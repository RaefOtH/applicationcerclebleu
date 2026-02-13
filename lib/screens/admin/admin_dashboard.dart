import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../painters/wave_painter.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../labo/lab_entry_choice_screen.dart';
import '../lek/lek_entry_choice_screen.dart';
import '../terrain/terrain_entry_choice_screen.dart';
import 'admin_researchers_screen.dart';
import 'admin_surveys_screen.dart';
import 'widgets/admin_role_guard.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser? user;

  const AdminDashboard({super.key, this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
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
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
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

  Future<void> _showCreateMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nouvelle saisie',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _menuTile(
                  icon: Icons.assignment_rounded,
                  label: 'Enquête : Données Terrain',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const TerrainEntryChoiceScreen(),
                      ),
                    );
                  },
                ),
                _menuTile(
                  icon: Icons.science_rounded,
                  label: 'Données laboratoire',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const LabEntryChoiceScreen(),
                      ),
                    );
                  },
                ),
                _menuTile(
                  icon: Icons.quiz_rounded,
                  label: 'Questionnaire LEK',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const LekEntryChoiceScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = (widget.user?.fullName ?? '').trim();
    final fullName = userName.isEmpty ? 'Admin' : userName;
    final email = (widget.user?.email ?? '').trim();

    return AdminRoleGuard(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateMenu,
          backgroundColor: const Color(0xFF00D9D9),
          child: const Icon(Icons.add_rounded),
        ),
        body: Stack(
          children: [
            SizedBox(
              height: 260,
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
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.profile,
                              arguments: {
                                'fullName': fullName,
                                'role': 'admin',
                                'email': email,
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cercle Bleu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dashboard Admin',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ActionCard(
                                icon: Icons.inventory_2_rounded,
                                title: 'Gestion des enquêtes',
                                subtitle:
                                    'Voir et filtrer toutes les saisies Terrain, Labo et LEK',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminSurveysScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _ActionCard(
                                icon: Icons.groups_rounded,
                                title: 'Gestion des chercheurs',
                                subtitle:
                                    'Consulter les profils, activités et détails des chercheurs',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminResearchersScreen(),
                                    ),
                                  );
                                },
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
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D9D9).withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)],
                ),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E3A8A)),
          ],
        ),
      ),
    );
  }
}
