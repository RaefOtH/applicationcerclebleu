import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TerrainFormService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createNewForm({bool waitForWrite = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }
    final roleCreateur = await _resolveCreatorRole(uid);
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    final title = 'Enquete Terrain - $dd/$mm/$yyyy';

    final docRef = _db.collection('terrain_forms').doc();
    final write = docRef.set({
      'ownerId': uid,
      'roleCreateur': roleCreateur,
      'title': title,
      'status': 'brouillon',
      'stepCompleted': 0,
      'data': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
    if (waitForWrite) {
      await write;
    }
    return docRef.id;
  }

  Future<String> _resolveCreatorRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final role = doc.data()?['role']?.toString().trim().toLowerCase();
    if (role == 'admin') return 'admin';
    return 'chercheur';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchForm(String formId) {
    return _db.collection('terrain_forms').doc(formId).snapshots();
  }

  Future<void> updateFormData(
    String formId,
    Map<String, dynamic> patch, {
    int? stepCompleted,
  }) async {
    final ref = _db.collection('terrain_forms').doc(formId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final currentStep = (snap.data()?['stepCompleted'] ?? 0) as int;
      final update = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(),
      };
      for (final entry in patch.entries) {
        update['data.${entry.key}'] = entry.value;
      }
      if (stepCompleted != null) {
        update['stepCompleted'] =
            stepCompleted > currentStep ? stepCompleted : currentStep;
      }
      tx.set(ref, update, SetOptions(merge: true));
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
        'status': 'soumise',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
