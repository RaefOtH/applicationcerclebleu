import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_db.dart';

class FirestoreTestResult {
  final bool ok;
  final String? docId;
  final String? errorCode;
  final String? errorMessage;

  const FirestoreTestResult({
    required this.ok,
    this.docId,
    this.errorCode,
    this.errorMessage,
  });
}

class FirestoreTestService {
  Future<FirestoreTestResult> run() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const FirestoreTestResult(
        ok: false,
        errorCode: 'unauthenticated',
        errorMessage: 'Utilisateur non connecte.',
      );
    }

    try {
      final ref = await FirestoreDb.db.collection('debug_tests').add({
        'ping': 'ok',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': currentUser.uid,
      });
      final check = await ref.get();
      if (!check.exists) {
        return FirestoreTestResult(
          ok: false,
          errorCode: 'read-failed',
          errorMessage: "Ecriture OK mais lecture impossible pour ${ref.id}.",
        );
      }
      return FirestoreTestResult(ok: true, docId: ref.id);
    } on FirebaseException catch (e) {
      return FirestoreTestResult(
        ok: false,
        errorCode: e.code,
        errorMessage: e.message ?? e.code,
      );
    } catch (e) {
      return FirestoreTestResult(
        ok: false,
        errorCode: 'unknown',
        errorMessage: e.toString(),
      );
    }
  }
}
