import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/attachment_item.dart';
import 'attachment_service.dart';
import 'export_service.dart';

class AttachmentDownloadService {
  final AttachmentService _attachmentService = AttachmentService();
  final ExportService _exportService = ExportService();

  Future<String> downloadAttachmentItem(AttachmentItem item) async {
    return _download(
      id: item.id,
      fileName: item.fileName,
      storagePath: item.storagePath,
      downloadUrl: item.downloadUrl,
      contentType: item.contentType,
      type: item.type,
      fallbackItem: item,
    );
  }

  Future<String> downloadAttachmentData(Map<String, dynamic> data) async {
    final id = (data['id'] ?? '').toString().trim();
    final fileName = (data['fileName'] ?? '').toString().trim();
    final storagePath = (data['storagePath'] ?? data['path'] ?? '')
        .toString()
        .trim();
    final downloadUrl = (data['downloadUrl'] ?? data['url'] ?? '')
        .toString()
        .trim();
    final contentType = (data['contentType'] ?? data['mimeType'] ?? '')
        .toString()
        .trim();
    var type = (data['type'] ?? '').toString().trim();
    if (type.isEmpty) {
      final ct = contentType.toLowerCase();
      if (ct.startsWith('image/')) {
        type = 'photo';
      } else if (ct.startsWith('audio/')) {
        type = 'audio';
      }
    }
    return _download(
      id: id,
      fileName: fileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: contentType,
      type: type,
      fallbackItem: null,
    );
  }

  Future<List<int>> readPreviewBytes(Map<String, dynamic> data) async {
    final id = (data['id'] ?? '').toString().trim();
    final fileName = (data['fileName'] ?? '').toString().trim();
    final storagePath = (data['storagePath'] ?? data['path'] ?? '')
        .toString()
        .trim();
    final downloadUrl = (data['downloadUrl'] ?? data['url'] ?? '')
        .toString()
        .trim();
    final contentType = (data['contentType'] ?? data['mimeType'] ?? '')
        .toString()
        .trim();
    var type = (data['type'] ?? '').toString().trim();
    if (type.isEmpty) {
      type = contentType.toLowerCase().startsWith('audio/')
          ? 'audio'
          : 'photo';
    }
    return _readBytes(
      id: id,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: contentType,
      type: type,
      fileName: fileName.isEmpty ? 'preview' : fileName,
      fallbackItem: null,
    );
  }

  Future<String> materializeTempFileData(Map<String, dynamic> data) async {
    final bytes = await readPreviewBytes(data);
    final id = (data['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    final contentType = (data['contentType'] ?? data['mimeType'] ?? '')
        .toString()
        .trim();
    final type = (data['type'] ?? '').toString().trim();
    final ext = _extFrom(contentType, type);
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/att_$id$ext');
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }

  Future<String> _download({
    required String id,
    required String fileName,
    required String storagePath,
    required String downloadUrl,
    required String contentType,
    required String type,
    AttachmentItem? fallbackItem,
  }) async {
    final safeName = _resolveFileName(
      id: id,
      rawName: fileName,
      storagePath: storagePath,
      contentType: contentType,
      type: type,
    );
    final bytes = await _readBytes(
      id: id,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: contentType,
      type: type,
      fallbackItem: fallbackItem,
      fileName: safeName,
    );
    final save = await _exportService.saveBytesToDevice(
      fileName: safeName,
      bytes: bytes,
    );
    return save.savedLocation;
  }

  Future<List<int>> _readBytes({
    required String id,
    required String storagePath,
    required String downloadUrl,
    required String contentType,
    required String type,
    required String fileName,
    required AttachmentItem? fallbackItem,
  }) async {
    if (downloadUrl.isNotEmpty) {
      final uri = Uri.tryParse(downloadUrl);
      if (uri != null) {
        final client = HttpClient();
        try {
          final req = await client.getUrl(uri);
          final res = await req.close();
          if (res.statusCode >= 200 && res.statusCode < 300) {
            final data = await consolidateHttpClientResponseBytes(res);
            if (data.isNotEmpty) return data;
          }
        } finally {
          client.close(force: true);
        }
      }
    }

    final firestoreId = _firestoreFileIdFromStoragePath(storagePath);
    if (firestoreId != null) {
      if (fallbackItem != null) {
        final bytes = await _attachmentService.readAttachmentBytes(fallbackItem);
        return bytes;
      }
      final map = <String, dynamic>{
        'type': type,
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': '',
        'contentType': contentType,
        'sizeBytes': 0,
        'createdBy': '',
        'createdByName': '',
        'formId': '',
        'formType': '',
        'createdAt': null,
      };
      final item = AttachmentItem.fromMap(id.isEmpty ? firestoreId : id, map);
      final bytes = await _attachmentService.readAttachmentBytes(item);
      return bytes;
    }

    if (storagePath.trim().isNotEmpty) {
      final bytes = await _readFromStoragePath(storagePath);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }

    throw StateError('Fichier introuvable pour telechargement.');
  }

  Future<List<int>?> _readFromStoragePath(String storagePath) async {
    final storages = _candidateStorages();
    for (final storage in storages) {
      try {
        final ref = storage.ref().child(storagePath);
        final bytes = await ref.getData(50 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        continue;
      }
    }
    return null;
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

    addStorage(FirebaseStorage.instance);
    final opts = Firebase.app().options;
    addBucket(opts.storageBucket ?? '');
    if (opts.projectId.trim().isNotEmpty) {
      addBucket('${opts.projectId}.appspot.com');
      addBucket('${opts.projectId}.firebasestorage.app');
    }
    return out;
  }

  String? _firestoreFileIdFromStoragePath(String storagePath) {
    const prefix = 'firestore://attachments_files/';
    if (!storagePath.startsWith(prefix)) return null;
    final id = storagePath.substring(prefix.length).trim();
    return id.isEmpty ? null : id;
  }

  String _resolveFileName({
    required String id,
    required String rawName,
    required String storagePath,
    required String contentType,
    required String type,
  }) {
    String out = rawName.trim();
    if (out.isEmpty && storagePath.trim().isNotEmpty) {
      final seg = storagePath.split('/').where((e) => e.trim().isNotEmpty);
      if (seg.isNotEmpty) {
        out = seg.last;
      }
    }
    if (out.isEmpty) {
      out = '${type.isEmpty ? 'attachment' : type}_${id.isEmpty ? DateTime.now().millisecondsSinceEpoch : id}';
    }
    if (!out.contains('.')) {
      out = '$out${_extFrom(contentType, type)}';
    }
    return out.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _extFrom(String contentType, String type) {
    final ct = contentType.toLowerCase();
    if (ct.contains('png')) return '.png';
    if (ct.contains('jpeg') || ct.contains('jpg')) return '.jpg';
    if (ct.contains('audio/mp4') || ct.contains('m4a')) return '.m4a';
    if (ct.contains('audio/mpeg')) return '.mp3';
    if (type == 'audio') return '.m4a';
    if (type == 'photo') return '.jpg';
    return '.bin';
  }
}
