import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/user_service.dart';

class TestAccounts {
  static bool _running = false;

  static Future<void> ensureCreated() async {
    if (!kDebugMode || _running) return;
    _running = true;

    final auth = FirebaseAuth.instance;
    final userService = UserService();

    await _ensureAccount(
      auth: auth,
      userService: userService,
      email: 'admin@test.com',
      password: '12345678',
      fullName: 'Admin Test',
      role: 'admin',
    );

    await _ensureAccount(
      auth: auth,
      userService: userService,
      email: 'chercheur@test.com',
      password: '12345678',
      fullName: 'Chercheur Test',
      role: 'chercheur',
    );

    await auth.signOut();
    _running = false;
  }

  static Future<void> _ensureAccount({
    required FirebaseAuth auth,
    required UserService userService,
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userService.createUserProfile(
        uid: cred.user!.uid,
        fullName: fullName,
        email: email,
        role: role,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
    }
  }
}
