import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../dashboard_screen.dart';

class ChercheurDashboard extends StatelessWidget {
  final AppUser? user;

  const ChercheurDashboard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      user: user,
      dashboardTitle: 'Dashboard Chercheur',
    );
  }
}
