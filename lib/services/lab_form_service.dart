import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LabFormService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String newFormId() {
    return _db.collection('lab_forms').doc().id;
  }

  Future<void> createFormWithId(
    String formId, {
    String? title,
    String? location,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }
    final roleCreateur = await _resolveCreatorRole(uid);
    final docRef = _db.collection('lab_forms').doc(formId);
    await docRef.set({
      'ownerId': uid,
      'roleCreateur': roleCreateur,
      'title': title ?? 'Donnees Labo',
      'location': location ?? '',
      'status': 'brouillon',
      'stepCompleted': 0,
      'data': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createNewForm({
    String? title,
    String? location,
    bool waitForWrite = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }
    final roleCreateur = await _resolveCreatorRole(uid);
    final docRef = _db.collection('lab_forms').doc();
    final payload = {
      'ownerId': uid,
      'roleCreateur': roleCreateur,
      'title': title ?? 'Donnees Labo',
      'location': location ?? '',
      'status': 'brouillon',
      'stepCompleted': 0,
      'data': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEditedAt': FieldValue.serverTimestamp(),
    };
    final write = docRef.set(payload);
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
    return _db.collection('lab_forms').doc(formId).snapshots();
  }

  Future<void> updateFormData(
    String formId,
    Map<String, dynamic> patch, {
    int? stepCompleted,
  }) async {
    final ref = _db.collection('lab_forms').doc(formId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final currentStep = (snap.data()?['stepCompleted'] ?? 0) as int;
      final update = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(),
      };
      if (patch.isNotEmpty) {
        for (final entry in patch.entries) {
          update['data.${entry.key}'] = entry.value;
        }
      }
      if (stepCompleted != null) {
        update['stepCompleted'] =
            stepCompleted > currentStep ? stepCompleted : currentStep;
      }
      tx.set(ref, update, SetOptions(merge: true));
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listMyForms() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }
    final snap = await _db
        .collection('lab_forms')
        .where('ownerId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyForms() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('lab_forms')
        .where('ownerId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> submitForm(String formId) async {
    await _db.collection('lab_forms').doc(formId).set(
      {
        'status': 'soumise',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteForm(String formId) async {
    await _db.collection('lab_forms').doc(formId).delete();
  }
}
