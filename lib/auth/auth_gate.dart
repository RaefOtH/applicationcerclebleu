import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/chercheur/chercheur_dashboard.dart';
import '../screens/login_screen.dart';
import '../services/user_service.dart';
import '../utils/auth_debug.dart';

enum _GateStateType { missingProfile, invalidRole, error, ready }

class _GateState {
  final _GateStateType type;
  final AppUser? profile;
  final String? message;
  final Object? error;

  const _GateState._({
    required this.type,
    this.profile,
    this.message,
    this.error,
  });

  const _GateState.ready(AppUser profile)
    : this._(type: _GateStateType.ready, profile: profile);
  const _GateState.missingProfile(String message)
    : this._(type: _GateStateType.missingProfile, message: message);
  const _GateState.invalidRole(String message)
    : this._(type: _GateStateType.invalidRole, message: message);
  const _GateState.error(Object error)
    : this._(type: _GateStateType.error, error: error);
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final UserService _userService = UserService();
  int _reloadToken = 0;
  bool _creatingProfile = false;

  Future<_GateState> _loadRoleState(User user) async {
    try {
      final profile = await _userService.getUserProfile(user.uid);
      if (profile == null) {
        return const _GateState.missingProfile(
          'Profil introuvable. Contactez l\u2019administrateur.',
        );
      }

      final role = profile.role.trim().toLowerCase();
      if (role != 'admin' && role != 'chercheur') {
        return _GateState.invalidRole(
          'R\u00F4le invalide : ${profile.role}. Corrigez dans Firestore.',
        );
      }

      authDebugLog('[AuthGate] uid=${user.uid} role_lu_firestore=$role');
      await _userService.updateLastLogin(user.uid);
      return _GateState.ready(profile);
    } catch (e) {
      authDebugLog('[AuthGate] erreur lecture profil: $e');
      return _GateState.error(e);
    }
  }

  Future<void> _retry() async {
    if (!mounted) return;
    setState(() => _reloadToken++);
  }

  Future<void> _createProfile(User user) async {
    final role = await _askRole(context);
    if (role == null) return;

    setState(() => _creatingProfile = true);
    try {
      final fullName = (user.displayName ?? '').trim().isEmpty
          ? 'Utilisateur'
          : user.displayName!.trim();
      await _userService.createUserProfile(
        uid: user.uid,
        fullName: fullName,
        email: user.email ?? '',
        role: role,
      );
      authDebugLog('[AuthGate] profil cree uid=${user.uid} role=$role');
      await _retry();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur creation profil: $e')));
    } finally {
      if (mounted) {
        setState(() => _creatingProfile = false);
      }
    }
  }

  Future<String?> _askRole(BuildContext context) async {
    String? selectedRole;
    final pinCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Creer profil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'chercheur',
                    groupValue: selectedRole,
                    onChanged: (v) => setLocalState(() => selectedRole = v),
                    title: const Text('Chercheur'),
                  ),
                  RadioListTile<String>(
                    value: 'admin',
                    groupValue: selectedRole,
                    onChanged: (v) => setLocalState(() => selectedRole = v),
                    title: const Text('Admin'),
                  ),
                  if (selectedRole == 'admin')
                    TextField(
                      controller: pinCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PIN Admin',
                        hintText: '0000',
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedRole == null) return;
                    if (selectedRole == 'admin' &&
                        pinCtrl.text.trim() != '0000') {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('PIN Admin incorrect')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, selectedRole);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
    pinCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
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

        return FutureBuilder<_GateState>(
          key: ValueKey('gate-load-${user.uid}-$_reloadToken'),
          future: _loadRoleState(user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return const _LoadingView();
            }

            final state = snapshot.data!;
            switch (state.type) {
              case _GateStateType.ready:
                final profile = state.profile!;
                if (profile.role.trim().toLowerCase() == 'admin') {
                  return AdminDashboard(user: profile);
                }
                return ChercheurDashboard(user: profile);
              case _GateStateType.missingProfile:
                return _StateMessageView(
                  title: 'Profil introuvable',
                  message: state.message!,
                  primaryLabel: _creatingProfile
                      ? 'Creation...'
                      : 'Creer profil',
                  onPrimary: _creatingProfile
                      ? null
                      : () => _createProfile(user),
                  secondaryLabel: 'Reessayer',
                  onSecondary: _retry,
                );
              case _GateStateType.invalidRole:
                return _StateMessageView(
                  title: 'Role invalide',
                  message: state.message!,
                  primaryLabel: 'Reessayer',
                  onPrimary: _retry,
                );
              case _GateStateType.error:
                return _StateMessageView(
                  title: 'Erreur',
                  message: 'Impossible de charger votre profil.',
                  details: state.error.toString(),
                  primaryLabel: 'Reessayer',
                  onPrimary: _retry,
                );
            }
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _StateMessageView extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StateMessageView({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.details,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF334155),
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    details!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
