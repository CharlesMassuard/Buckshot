import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/buckshot_theme.dart';
import 'login_view.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/password_section.dart';
import '../widgets/organisation_section.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isSuccess ? BuckshotTheme.successColor.withValues(alpha: 0.8) : theme.colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final passwordCheckController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Suppression définitive", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cette action est irréversible. Saisissez votre mot de passe pour confirmer :",
              style: GoogleFonts.jura(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCheckController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                hintText: "Mot de passe",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler", style: GoogleFonts.jura(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              final pwd = passwordCheckController.text.trim();
              if (pwd.isEmpty) return;

              try {
                AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: pwd);
                await user.reauthenticateWithCredential(credential);

                await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                await FirebaseFirestore.instance.collection('demandes_organisation').doc(user.uid).delete();
                await user.delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                _showSnackBar("Erreur lors de la suppression : ${e.toString()}");
              }
            },
            child: Text("Supprimer", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    bool isEmailProvider = false;
    if (user != null) {
      for (var profile in user.providerData) {
        if (profile.providerId == 'password') {
          isEmailProvider = true;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Gestion du compte',
          style: GoogleFonts.jura(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.secondary, size: 28),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final String email = userData?['email'] ?? '';
          final String prenom = userData?['prenom'] ?? '';
          final String nom = userData?['nom'] ?? '';
          final String role = userData?['role'] ?? 'USER';
          final String currentOrg = (userData?['idOrganisateur'] ?? '').toString().trim();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // 1. Formulaire Prénom / Nom
                ProfileInfoSection(
                  email: email,
                  initialFirstName: prenom,
                  initialLastName: nom,
                  userId: user?.uid ?? '',
                  onShowSnackBar: _showSnackBar,
                ),

                const SizedBox(height: 24),

                // 2. Section de Sécurité (Mot de passe)
                if (isEmailProvider)
                  PasswordSection(onShowSnackBar: _showSnackBar)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Text(
                      "Connecté via un fournisseur externe. Gestion du mot de passe indisponible. 🌐",
                      style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. Section Structures & Organisations
                OrganisationSection(
                  role: role,
                  currentOrg: currentOrg,
                  userId: user?.uid ?? '',
                  userFullName: "$prenom $nom",
                  onShowSnackBar: _showSnackBar,
                ),

                const SizedBox(height: 32),

                // 4. Bouton de suppression du compte
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                  ),
                  onPressed: _deleteAccount,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_remove_outlined, color: theme.colorScheme.error, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Supprimer mon compte",
                        style: GoogleFonts.jura(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}