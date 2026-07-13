import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment_item.dart';
import 'firestore_db.dart';

class AttachmentService {
  final FirebaseFirestore _db = FirestoreDb.db;
  final AudioRecorder _recorder = AudioRecorder();
  final Uuid _uuid = const Uuid();

  String _formsCollection(String formType) {
    
    return formType == 'terrain' ? 'terrain_forms' : formType == 'lab' ? 'lab_forms': 'lek_forms';
  }

  CollectionReference<Map<String, dynamic>> _attachmentsCol({
    required String formType,
    required String formId,
  }) {
    return _db
        .collection(_formsCollection(formType))
        .doc(formId)
        .collection('attachments');
  }

  Never _fail(String message) => throw StateError(message);

  void _diag(String message) {
    if (kDebugMode) {
      debugPrint('ATTACH_DEBUG $message');
    }
  }

  Future<User> _requireUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) _fail('Utilisateur non connecté.');
    return user;
  }

  Future<String> _currentUserName(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final fullName = (userDoc.data()?['fullName'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    final fallback = FirebaseAuth.instance.currentUser?.displayName ?? '';
    if (fallback.trim().isNotEmpty) return fallback.trim();
    return 'Utilisateur';
  }

  Future<void> _ensureFormExists({
    required String formType,
    required String formId,
  }) async {
    if (formId.trim().isEmpty) {
      _fail('Formulaire introuvable. Créez le formulaire avant upload.');
    }
    final user = await _requireUser();
    final ref = _db.collection(_formsCollection(formType)).doc(formId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'ownerId': user.uid,
      'type': formType,
      'status': 'brouillon',
      'stepCompleted': 0,
      'data': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<FirebaseStorage> _candidateStorages() {
    final out = <FirebaseStorage>[];
    final seen = <String>{};

    void addStorage(FirebaseStorage storage) {
      final key = storage.bucket.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      out.add(storage);
    }

    void addBucket(String raw) {
      final cleaned = raw.trim().replaceFirst('gs://', '');
      if (cleaned.isEmpty) return;
      final key = cleaned.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      out.add(FirebaseStorage.instanceFor(bucket: 'gs://$cleaned'));
    }

    final opts = Firebase.app().options;
    // Always try SDK default first; on some projects this is the only working mapping.
    addStorage(FirebaseStorage.instance);
    addBucket(opts.storageBucket ?? '');

    final configured = (opts.storageBucket ?? '').trim();
    if (configured.endsWith('.firebasestorage.app')) {
      addBucket(
        configured.replaceFirst('.firebasestorage.app', '.appspot.com'),
      );
    } else if (configured.endsWith('.appspot.com')) {
      addBucket(
        configured.replaceFirst('.appspot.com', '.firebasestorage.app'),
      );
    }

    if (opts.projectId.trim().isNotEmpty) {
      addBucket('${opts.projectId}.firebasestorage.app');
      addBucket('${opts.projectId}.appspot.com');
    }

    if (out.isEmpty) {
      out.add(FirebaseStorage.instance);
    }
    return out;
  }

  String _safeExtFromPath(String path, String fallback) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.jpeg')) return 'jpeg';
    if (p.endsWith('.jpg')) return 'jpg';
    if (p.endsWith('.m4a')) return 'm4a';
    return fallback;
  }

  String? _firestoreFileIdFromStoragePath(String storagePath) {
    const prefix = 'firestore://attachments_files/';
    if (!storagePath.startsWith(prefix)) return null;
    final id = storagePath.substring(prefix.length).trim();
    return id.isEmpty ? null : id;
  }

  String _buildStoragePath({
    required String formType,
    required String formId,
    required bool isAudio,
    required String ext,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final folder = isAudio ? 'audio' : 'photos';
    return 'attachments/$formType/$formId/$folder/${ts}_${_uuid.v4().replaceAll('-', '')}.$ext';
  }

  Future<String> _urlWithRetry(Reference ref) async {
    Object? lastError;
    for (var i = 0; i < 6; i++) {
      try {
        return await ref.getDownloadURL();
      } catch (e) {
        lastError = e;
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }
    throw lastError ?? StateError('URL introuvable après upload.');
  }

  Future<_UploadResult> _uploadWithDiagnostics({
    required File file,
    required String storagePath,
    required SettableMetadata metadata,
  }) async {
    final opts = Firebase.app().options;
    _diag(
      'init projectId=${opts.projectId} '
      'appId=${opts.appId} '
      'storageBucket=${opts.storageBucket} '
      'localPath=${file.path}',
    );

    final fileExists = file.existsSync();
    final size = fileExists ? await file.length() : 0;
    final ext = file.path.contains('.') ? file.path.split('.').last : '';
    _diag('local exists=$fileExists size=$size ext=$ext');
    if (!fileExists || size <= 0) {
      _fail('Enregistrement audio invalide (fichier absent ou vide).');
    }

    String lastDiag = '';
    final storages = _candidateStorages();

    for (final storage in storages) {
      final ref = storage.ref().child(storagePath);
      _diag('try bucket=${storage.bucket} path=${ref.fullPath}');
      try {
        _diag('stage=putFile start path=${ref.fullPath}');
        final task = ref.putFile(file, metadata);
        task.snapshotEvents.listen((event) {
          _diag(
            'progress state=${event.state.name} '
            'bytes=${event.bytesTransferred}/${event.totalBytes}',
          );
        });

        await task.whenComplete(() {});
        final snap = await task;
        _diag(
          'done state=${snap.state.name} '
          'bytes=${snap.bytesTransferred}/${snap.totalBytes} '
          'snapPath=${snap.ref.fullPath}',
        );
        if (snap.state != TaskState.success) {
          lastDiag = 'upload incomplet sur ${storage.bucket}';
          continue;
        }

        _diag('stage=getDownloadURL start path=${snap.ref.fullPath}');
        final url = await _urlWithRetry(snap.ref);
        _diag('downloadUrl=$url');
        return _UploadResult(
          storagePath: snap.ref.fullPath,
          downloadUrl: url,
          sizeBytes: size,
        );
      } on FirebaseException catch (e) {
        lastDiag =
            'bucket=${storage.bucket} stage=putFile|getDownloadURL '
            'code=${e.code} msg=${e.message ?? ''}';
        _diag('error $lastDiag');
        if (e.code != 'object-not-found') {
          break;
        }
      } catch (e) {
        lastDiag = 'bucket=${storage.bucket} error=$e';
        _diag('error $lastDiag');
      }
    }

    _fail(
      'Erreur upload [object-not-found]. Le fichier n’a pas été uploadé '
      'ou bucket incorrect. Détail: $lastDiag. '
      'Vérifiez Firebase Storage activé dans la console.',
    );
  }

  Future<_UploadResult> _storeInFirestoreChunks({
    required String attachmentId,
    required File file,
    required String formType,
    required String formId,
    required String ownerId,
    required String ownerName,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();
    final size = bytes.length;
    const chunkSize = 700 * 1024;
    final chunksCount = (size / chunkSize).ceil();
    final rootRef = _db.collection('attachments_files').doc(attachmentId);

    await rootRef.set({
      'formId': formId,
      'formType': formType,
      'ownerId': ownerId,
      'storagePath': 'firestore://attachments_files/$attachmentId',
      'downloadUrl': '',
      'contentType': contentType,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'createdByName': ownerName,
      'chunksCount': chunksCount,
      'sizeBytes': size,
    }, SetOptions(merge: true));

    WriteBatch batch = _db.batch();
    var writes = 0;
    for (var i = 0; i < chunksCount; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize > size) ? size : start + chunkSize;
      final chunk = bytes.sublist(start, end);
      final chunkRef = rootRef.collection('chunks').doc(i.toString());
      batch.set(chunkRef, {'i': i, 'data': Blob(chunk)});
      writes++;
      if (writes >= 400) {
        await batch.commit();
        batch = _db.batch();
        writes = 0;
      }
    }
    if (writes > 0) {
      await batch.commit();
    }

    _diag('fallback firestore chunks saved id=$attachmentId size=$size');
    return _UploadResult(
      storagePath: 'firestore://attachments_files/$attachmentId',
      downloadUrl: '',
      sizeBytes: size,
    );
  }

  Future<void> _touchParentForm(String formType, String formId) async {
    await _db.collection(_formsCollection(formType)).doc(formId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _extractPlaceFromForm({
    required String formType,
    required String formId,
  }) async {
    try {
      final snap = await _db.collection(_formsCollection(formType)).doc(formId).get();
      final data = snap.data();
      if (data == null) return '';
      final map = data['data'];
      Map<String, dynamic> payload = const {};
      if (map is Map<String, dynamic>) {
        payload = map;
      } else if (map is Map) {
        payload = map.map((k, v) => MapEntry(k.toString(), v));
      }

      String pick(String key) => (payload[key] ?? '').toString().trim();

      final candidates = <String>[
        pick('gen_portPecheAutre'),
        pick('gen_portPeche'),
        pick('lab_nomLaboratoire'),
        pick('lab_laboratoire'),
        pick('ana_laboratoire'),
      ];
      return candidates.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    } catch (_) {
      return '';
    }
  }

  Future<AttachmentItem> uploadPhoto({
    required String formType,
    required String formId,
    required File file,
    required String ownerId,
    required String ownerName,
  }) async {
    await _ensureFormExists(formType: formType, formId: formId);
    await _requireUser();
    if (!await file.exists()) _fail('Photo introuvable sur l’appareil.');

    final ext = _safeExtFromPath(file.path, 'jpg');
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final place = await _extractPlaceFromForm(formType: formType, formId: formId);
    final storagePath = _buildStoragePath(
      formType: formType,
      formId: formId,
      isAudio: false,
      ext: ext,
    );
    final attRef = _attachmentsCol(formType: formType, formId: formId).doc();
    _UploadResult upload;
    try {
      upload = await _uploadWithDiagnostics(
        file: file,
        storagePath: storagePath,
        metadata: SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'ownerId': ownerId,
            'formId': formId,
            'formType': formType,
          },
        ),
      );
    } catch (e) {
      _diag('storage photo failed, fallback firestore chunks: $e');
      upload = await _storeInFirestoreChunks(
        attachmentId: attRef.id,
        file: file,
        formType: formType,
        formId: formId,
        ownerId: ownerId,
        ownerName: ownerName,
        contentType: contentType,
      );
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'photo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await attRef.set({
      'type': 'photo',
      'url': upload.downloadUrl,
      'path': upload.storagePath,
      'fileName': fileName,
      'storagePath': upload.storagePath,
      'downloadUrl': upload.downloadUrl,
      'contentType': contentType,
      'size': upload.sizeBytes,
      'sizeBytes': upload.sizeBytes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'ownerId': ownerId,
      'createdByName': ownerName,
      'ownerName': ownerName,
      'formId': formId,
      'formType': formType,
      'place': place,
      'mimeType': contentType,
    }, SetOptions(merge: true));

    await _db.collection('attachments_files').doc(attRef.id).set({
      'type': 'photo',
      'fileName': fileName,
      'collection': _formsCollection(formType),
      'formId': formId,
      'formType': formType,
      'place': place,
      'ownerId': ownerId,
      'storagePath': upload.storagePath,
      'downloadUrl': upload.downloadUrl,
      'contentType': contentType,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'createdByName': ownerName,
      'sizeBytes': upload.sizeBytes,
    }, SetOptions(merge: true));

    await _touchParentForm(formType, formId);
    final created = await attRef.get();
    return AttachmentItem.fromFirestore(created);
  }

  Future<String> startAudioRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _diag('recordStart path=$path');
    return path;
  }

  Future<File> stopAudioRecordingFile() async {
    final localPath = await _recorder.stop();
    _diag('recordStop path=$localPath');
    if (localPath == null || localPath.trim().isEmpty) {
      _fail('Enregistrement audio invalide.');
    }
    final file = File(localPath);
    if (!file.existsSync()) {
      _fail('Enregistrement audio invalide (fichier absent).');
    }
    final len = await file.length();
    if (len <= 0) {
      _fail('Enregistrement audio invalide (fichier vide).');
    }
    _diag('recordFile exists=${file.existsSync()} size=$len');
    return file;
  }

  Future<AttachmentItem> uploadAudio({
    required String formType,
    required String formId,
    required File file,
    required String ownerId,
    required String ownerName,
  }) async {
    await _ensureFormExists(formType: formType, formId: formId);
    await _requireUser();
    if (!await file.exists()) {
      _fail('Enregistrement audio invalide (fichier absent).');
    }
    final fileLen = await file.length();
    if (fileLen <= 0) {
      _fail('Enregistrement audio invalide (fichier vide).');
    }
    if (_safeExtFromPath(file.path, 'm4a') != 'm4a') {
      _diag('warning ext audio non m4a: ${file.path}');
    }
    final place = await _extractPlaceFromForm(formType: formType, formId: formId);

    final storagePath = _buildStoragePath(
      formType: formType,
      formId: formId,
      isAudio: true,
      ext: 'm4a',
    );
    final attRef = _attachmentsCol(formType: formType, formId: formId).doc();
    _UploadResult upload;
    try {
      upload = await _uploadWithDiagnostics(
        file: file,
        storagePath: storagePath,
        metadata: SettableMetadata(
          contentType: 'audio/mp4',
          customMetadata: {
            'ownerId': ownerId,
            'formId': formId,
            'formType': formType,
          },
        ),
      );
    } catch (e) {
      _diag('storage audio failed, fallback firestore chunks: $e');
      upload = await _storeInFirestoreChunks(
        attachmentId: attRef.id,
        file: file,
        formType: formType,
        formId: formId,
        ownerId: ownerId,
        ownerName: ownerName,
        contentType: 'audio/mp4',
      );
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await attRef.set({
      'type': 'audio',
      'url': upload.downloadUrl,
      'path': upload.storagePath,
      'fileName': fileName,
      'storagePath': upload.storagePath,
      'downloadUrl': upload.downloadUrl,
      'contentType': 'audio/mp4',
      'size': upload.sizeBytes,
      'sizeBytes': upload.sizeBytes,
      'durationMs': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'ownerId': ownerId,
      'createdByName': ownerName,
      'ownerName': ownerName,
      'formId': formId,
      'formType': formType,
      'place': place,
      'mimeType': 'audio/mp4',
    }, SetOptions(merge: true));

    await _db.collection('attachments_files').doc(attRef.id).set({
      'type': 'audio',
      'fileName': fileName,
      'collection': _formsCollection(formType),
      'formId': formId,
      'formType': formType,
      'place': place,
      'ownerId': ownerId,
      'storagePath': upload.storagePath,
      'downloadUrl': upload.downloadUrl,
      'contentType': 'audio/mp4',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'createdByName': ownerName,
      'sizeBytes': upload.sizeBytes,
    }, SetOptions(merge: true));

    await _touchParentForm(formType, formId);
    final created = await attRef.get();
    return AttachmentItem.fromFirestore(created);
  }

  Stream<List<AttachmentItem>> watchAttachments({
    required String formType,
    required String formId,
    String? type,
  }) {
    if (formId.trim().isEmpty) {
      return const Stream<List<AttachmentItem>>.empty();
    }
    Query<Map<String, dynamic>> query = _attachmentsCol(
      formType: formType,
      formId: formId,
    );
    if (type != null && type.trim().isNotEmpty) {
      query = query.where('type', isEqualTo: type.trim());
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttachmentItem.fromFirestore).toList());
  }

  Future<void> deleteAttachment({
    required String formType,
    required String formId,
    required AttachmentItem att,
  }) async {
    await _requireUser();
    final attRef = _attachmentsCol(
      formType: formType,
      formId: formId,
    ).doc(att.id);
    final firestoreFileId = _firestoreFileIdFromStoragePath(att.storagePath);
    if (firestoreFileId != null) {
      final rootRef = _db.collection('attachments_files').doc(firestoreFileId);
      final chunks = await rootRef.collection('chunks').get();
      WriteBatch batch = _db.batch();
      var count = 0;
      for (final chunk in chunks.docs) {
        batch.delete(chunk.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      await rootRef.delete();
    } else if (att.storagePath.trim().isNotEmpty) {
      Object? lastErr;
      for (final storage in _candidateStorages()) {
        try {
          await storage.ref().child(att.storagePath).delete();
          lastErr = null;
          break;
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            lastErr = e;
            continue;
          }
          rethrow;
        } catch (e) {
          lastErr = e;
        }
      }
      if (lastErr != null) {
        _diag('deleteStorage skipped/error: $lastErr');
      }
    }
    await attRef.delete();
    await _db.collection('attachments_files').doc(att.id).delete();
    await _touchParentForm(formType, formId);
  }

  Future<Uint8List> readAttachmentBytes(AttachmentItem att) async {
    final fileId = _firestoreFileIdFromStoragePath(att.storagePath);
    if (fileId == null) {
      _fail('Pièce jointe non stockée dans Firestore chunks.');
    }
    final rootRef = _db.collection('attachments_files').doc(fileId);
    final chunksSnap = await rootRef.collection('chunks').orderBy('i').get();
    if (chunksSnap.docs.isEmpty) {
      _fail('Aucun chunk trouvé pour ce fichier.');
    }
    final builder = BytesBuilder(copy: false);
    for (final doc in chunksSnap.docs) {
      final data = doc.data()['data'];
      if (data is Blob) {
        builder.add(data.bytes);
      }
    }
    return builder.takeBytes();
  }

  Future<String> materializeAttachmentTempFile(AttachmentItem att) async {
    final bytes = await readAttachmentBytes(att);
    final ext = att.type == 'audio' ? 'm4a' : 'bin';
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/att_${att.id}.$ext');
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }

  Future<bool> canDeleteAttachment(AttachmentItem att) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (att.createdBy == user.uid) return true;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
    return role == 'admin';
  }

  Future<Map<String, String>> currentOwnerInfo() async {
    final user = await _requireUser();
    final name = await _currentUserName(user.uid);
    return {'uid': user.uid, 'name': name};
  }

  Future<void> stopRecordingIfNeeded() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}

class _UploadResult {
  final String storagePath;
  final String downloadUrl;
  final int sizeBytes;

  const _UploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}
