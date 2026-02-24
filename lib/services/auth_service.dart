import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  String mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'email-already-in-use':
        return 'Cet email est deja utilise.';
      case 'user-not-found':
        return 'Utilisateur introuvable.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'network-request-failed':
        return 'Erreur reseau. Verifiez votre connexion.';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez plus tard.';
      default:
        return 'Erreur de connexion.';
    }
  }
}
