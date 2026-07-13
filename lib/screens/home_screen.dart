import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../models/user_mock.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/big_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Déclenche la vérification de mise à jour automatiquement dès que l'écran est affiché
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndUpdate(context);
    });
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à venir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final user = args is UserMock ? args : null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppTheme.limeYellow,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const SafeArea(
            child: Row(
              children: [
                Icon(Icons.person, size: 28),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Bonjour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              user?.fullName ?? 'UTILISATEUR',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            BigActionCard(
              text: 'Remplir enquête',
              color: AppTheme.primaryGreen,
              icon: Icons.assignment_turned_in,
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppTheme.limeYellow,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.home),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.power_settings_new),
              ),
            ],
          ),
        ),
      ),
    );
  }
}