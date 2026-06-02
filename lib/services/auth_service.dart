import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          throw "T'es qui toi ? Utilisateur inconnu ou infos erronées. 🕵️";
        case 'wrong-password':
          throw "Mot de passe foiré. Respire et réessaie. 🔑";
        case 'invalid-email':
          throw "C'est pas un email valide ça, chef. 📧";
        default:
          throw "Identifiants invalides ou erreur réseau... 🌐";
      }
    } catch (e) {
      throw "Une erreur inattendue est survenue... 💥";
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Cet email est déjà utilisé par un autre compte';
        case 'invalid-email':
          throw 'Format de l\'email invalide';
        case 'weak-password':
          throw 'Le mot de passe est trop faible';
        default:
          throw 'Une erreur est survenue lors de l\'inscription';
      }
    } catch (e) {
      throw 'Une erreur inattendue est survenue';
    }
  }


Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw "C'est pas un email valide ça, chef. 📧";
        case 'user-not-found':
          throw "Aucun compte n'est lié à cet email. 🕵️";
        default:
          throw "Erreur lors de l'envoi de l'email... 🌐";
      }
    } catch (e) {
      throw "Une erreur inattendue est survenue... 💥";
    }
  }
}