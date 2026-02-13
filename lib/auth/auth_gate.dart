import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/chercheur/chercheur_dashboard.dart';
import '../screens/login_screen.dart';
import '../services/user_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const Duration _firestoreTimeout = Duration(seconds: 6);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<AppUser?>(
          future: _bootstrapProfile(userService, user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }
            final profile = snapshot.data ?? _fallbackUser(user);
            if (profile.role == 'admin') {
              return AdminDashboard(user: profile);
            }
            return ChercheurDashboard(user: profile);
          },
        );
      },
    );
  }

  Future<AppUser?> _bootstrapProfile(UserService userService, User user) async {
    try {
      final existing = await userService
          .getUserProfile(user.uid)
          .timeout(_firestoreTimeout, onTimeout: () => null);
      final fallback = _fallbackUser(user);
      if (existing == null) {
        userService
            .createUserProfile(
              uid: user.uid,
              fullName: fallback.fullName,
              email: fallback.email,
              role: fallback.role,
            )
            .timeout(_firestoreTimeout)
            .catchError((_) {});
        return fallback;
      }

      final needsPatch = existing.fullName.trim().isEmpty ||
          existing.email.trim().isEmpty ||
          existing.role.trim().isEmpty;
      if (needsPatch) {
        userService
            .createUserProfile(
              uid: user.uid,
              fullName: existing.fullName.trim().isEmpty
                  ? fallback.fullName
                  : existing.fullName,
              email: existing.email.trim().isEmpty
                  ? fallback.email
                  : existing.email,
              role: existing.role.trim().isEmpty ? 'chercheur' : existing.role,
            )
            .timeout(_firestoreTimeout)
            .catchError((_) {});
      }

      userService
          .updateLastLogin(user.uid)
          .timeout(_firestoreTimeout)
          .catchError((_) {});
      return existing;
    } catch (_) {
      return _fallbackUser(user);
    }
  }

  AppUser _fallbackUser(User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim() ?? '';
    final fullName = displayName.isNotEmpty ? displayName : 'Utilisateur';
    return AppUser(
      uid: user.uid,
      email: email,
      fullName: fullName,
      role: 'chercheur',
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
