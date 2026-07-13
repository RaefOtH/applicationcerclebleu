import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../painters/wave_painter.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  bool _loading = false;
  String _selectedRole = 'chercheur';
  String? _emailErrorText; // <-- Pour gérer l'erreur de l'email en rouge
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Écouter les changements de l'email pour retirer le rouge dès que l'utilisateur corrige
    _emailController.addListener(() {
      if (_emailErrorText != null) {
        setState(() => _emailErrorText = null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Contrôle du format de l'email (Détection visuelle rouge)
    if (!_isValidEmail(email)) {
      setState(() {
        _emailErrorText = "Le format de l'e-mail n'est pas valide ou cet e-mail n'existe pas.";
      });
      return;
    }

    if (fullName.isEmpty || password.isEmpty) {
      _showSnack('Veuillez remplir tous les champs');
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showSnack('Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial.');
      return;
    }
    
    if (_selectedRole == 'admin') {
      final pin = _pinController.text.trim();
      if (pin.isEmpty) {
        _showSnack('Code PIN Admin requis');
        return;
      }
      if (pin != '0000') {
        _showSnack('Code PIN Admin incorrect');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      // Création du compte Firebase Auth
      final cred = await _authService.register(email, password);
      final user = cred.user;
      if (user == null) throw Exception('Utilisateur introuvable');

      // 2. Envoi de l'e-mail de vérification (seul juge de la réalité de l'adresse)
      await user.sendEmailVerification();

      // 3. Création du profil utilisateur en mode "non vérifié" ou en attente
      await _userService.createUserProfile(
        uid: user.uid,
        fullName: fullName,
        email: email,
        role: _selectedRole,
      );

      // On déconnecte immédiatement pour détruire la session active non vérifiée
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Boîte de dialogue explicite
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Vérification requise'),
          content: Text('Un lien de confirmation a été envoyé à $email. L\'inscription ne sera validée que lorsque vous aurez cliqué sur ce lien.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte
                Navigator.pop(context); // Retourne à la page de Login
              },
              child: const Text('Compris'),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      _showSnack(_authService.mapError(e));
    } catch (_) {
      _showSnack('Erreur lors de l’inscription');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8), Color(0xFF1E3A8A)],
                ),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withValues(alpha: 0.12),
                      waveHeight: 18,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Column(children: [_buildCard(context)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 220, height: 160, fit: BoxFit.contain),
          const SizedBox(height: 8),
          const Text('Inscription', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 20),
          _buildTextField(controller: _nameController, hint: 'Nom complet', icon: Icons.person_outline),
          const SizedBox(height: 12),
          
          // CHAMP EMAIL MODIFIÉ (Prend en compte l'état d'erreur rouge)
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email_outlined,
            errorText: _emailErrorText, 
          ),
          
          const SizedBox(height: 12),
          _buildTextField(controller: _passwordController, hint: 'Mot de passe', icon: Icons.lock_outline, obscureText: true),
          const SizedBox(height: 12),
          _buildRoleSelector(),
          if (_selectedRole == 'admin') ...[
            const SizedBox(height: 12),
            _buildTextField(controller: _pinController, hint: 'Code PIN Admin', icon: Icons.lock_outline, obscureText: true),
          ],
          const SizedBox(height: 20),
          _buildGradientButton(
            text: _loading ? 'Création...' : 'Créer mon compte',
            onPressed: _loading ? null : _register,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? errorText, // <-- Ajouté
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.white,
        errorText: errorText, // S'affiche en rouge si non null
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00D9D9), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Type de compte', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _roleChip('chercheur', 'Chercheur')),
            const SizedBox(width: 10),
            Expanded(child: _roleChip('admin', 'Admin')),
          ],
        ),
      ],
    );
  }

  Widget _roleChip(String value, String label) {
    final isSelected = _selectedRole == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D9D9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF00D9D9) : Colors.grey.shade300),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E3A8A), fontWeight: FontWeight.w600))),
      ),
    );
  }
}