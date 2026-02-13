import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LekFormService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createNewForm({bool waitForWrite = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Utilisateur non connecte');
    }

    final roleCreateur = await _resolveCreatorRole(uid);
    final docRef = _db.collection('lek_forms').doc();
    final write = docRef.set({
      'ownerId': uid,
      'roleCreateur': roleCreateur,
      'title': 'Questionnaire LEK',
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
}
