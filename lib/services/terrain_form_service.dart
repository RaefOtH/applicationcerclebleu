import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firestore_db.dart';

class TerrainFormService {
  final FirebaseFirestore _db = FirestoreDb.db;
  final Map<String, Timer> _saveTimers = {};
  static const Duration _writeTimeout = Duration(seconds: 10);

  Future<String> createNewForm({bool waitForWrite = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    final roleCreateur = await _resolveCreatorRole(uid);
    final ownerName = await _resolveOwnerName(uid, currentUser?.displayName);
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    final title = 'Enquete Terrain - $dd/$mm/$yyyy';

    final docRef = _db.collection('terrain_forms').doc();
    final write = docRef.set({
      'ownerId': uid,
      'ownerName': ownerName,
      'role': roleCreateur,
      'roleCreateur': roleCreateur,
      'type': 'terrain',
      'title': title,
      'status': 'brouillon',
      'stepCompleted': 0,
      'data': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
    if (waitForWrite) {
      await write.timeout(_writeTimeout);
    }
    return docRef.id;
  }

  Future<String> _resolveCreatorRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final role = doc.data()?['role']?.toString().trim().toLowerCase();
    if (role == 'admin') return 'admin';
    return 'chercheur';
  }

  Future<String> _resolveOwnerName(String uid, String? fallbackDisplayName) async {
    final doc = await _db.collection('users').doc(uid).get();
    final fullName = doc.data()?['fullName']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final fallback = (fallbackDisplayName ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    return 'Utilisateur';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchForm(String formId) {
    return _db.collection('terrain_forms').doc(formId).snapshots();
  }

  Future<void> updateFormData(
    String formId,
    Map<String, dynamic> fullData, {
    int? stepCompleted,
  }) async {
    final ref = _db.collection('terrain_forms').doc(formId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final rawStep = snap.data()?['stepCompleted'];
      final currentStep = rawStep is int
          ? rawStep
          : rawStep is num
              ? rawStep.toInt()
              : int.tryParse(rawStep?.toString() ?? '') ?? 0;
      final update = <String, dynamic>{
        'data': Map<String, dynamic>.from(fullData),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(),
      };
      if (stepCompleted != null) {
        update['stepCompleted'] =
            stepCompleted > currentStep ? stepCompleted : currentStep;
      }
      print('SAVE FULL DATA terrain => ${fullData.length} keys');
      tx.set(ref, update, SetOptions(merge: true));
    });
  }

  void scheduleFullDataSave(
    String formId,
    Map<String, dynamic> fullData, {
    int? stepCompleted,
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _saveTimers[formId]?.cancel();
    _saveTimers[formId] = Timer(delay, () {
      updateFormData(formId, fullData, stepCompleted: stepCompleted)
          .catchError((e) {
        print('SAVE FULL DATA terrain failed => $e');
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyForms() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('terrain_forms')
        .where('ownerId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteForm(String formId) async {
    await _db.collection('terrain_forms').doc(formId).delete();
  }

  Future<void> submitForm(String formId) async {
    await _db.collection('terrain_forms').doc(formId).set(
      {
        'status': 'soumis',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}


