import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../painters/wave_painter.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Deconnexion'),
          content: const Text('Voulez-vous vous deconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se deconnecter'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.authGate,
      (route) => false,
    );
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'N/A';
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _displayRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    if (role == 'admin') return 'Admin';
    if (role == 'chercheur') return 'Chercheur';
    return rawRole;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : <String, dynamic>{};
    final fallbackFullName = _safeText(map['fullName'], 'Utilisateur');
    final fallbackRole = _safeText(map['role'], 'chercheur');
    final fallbackEmail = _safeText(map['email'], 'N/A');

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2D4BA8),
                    Color(0xFF1E3A8A),
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withOpacity(0.12),
                      waveHeight: 20,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D9D9).withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/image/logo.png',
                                  height: 110,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: currentUser == null
                                  ? Column(
                                      children: [
                                        _buildInfoRow(
                                            'Nom complet', fallbackFullName),
                                        _buildInfoRow('Email', fallbackEmail),
                                        _buildInfoRow(
                                          'Role',
                                          _displayRole(fallbackRole),
                                        ),
                                        _buildInfoRow('Telephone', 'N/A'),
                                        _buildInfoRow('Date creation', 'N/A'),
                                      ],
                                    )
                                  : StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser.uid)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        final data = snapshot.data?.data() ?? {};
                                        final fullName = _safeText(
                                          data['fullName'],
                                          fallbackFullName,
                                        );
                                        final email = _safeText(
                                          data['email'],
                                          fallbackEmail,
                                        );
                                        final role = _displayRole(
                                          _safeText(data['role'], fallbackRole),
                                        );
                                        final phone = _safeText(
                                          data['phone'],
                                          'N/A',
                                        );
                                        final createdAt = _formatDate(
                                          _asDate(data['createdAt']),
                                        );
                                        return Column(
                                          children: [
                                            _buildInfoRow('Nom complet', fullName),
                                            _buildInfoRow('Email', email),
                                            _buildInfoRow('Role', role),
                                            _buildInfoRow('Telephone', phone),
                                            _buildInfoRow(
                                              'Date creation',
                                              createdAt,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00D9D9),
                                      Color(0xFF00B8B8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D9D9).withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _confirmLogout,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      child: Center(
                                        child: Text(
                                          'Se deconnecter',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
