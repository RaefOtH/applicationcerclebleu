import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../models/app_user.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/chercheur/chercheur_dashboard.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String authGate = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String chercheurDashboard = '/chercheur-dashboard';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        authGate: (context) => const AuthGate(),
        home: (context) => const AuthGate(),
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        dashboard: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final user = args is AppUser ? args : null;
          return DashboardScreen(user: user);
        },
        adminDashboard: (context) => const AdminDashboard(),
        chercheurDashboard: (context) => const ChercheurDashboard(),
        profile: (context) => const ProfileScreen(),
      };
}
