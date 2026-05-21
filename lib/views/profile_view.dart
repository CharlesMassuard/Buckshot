import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/BuckshotTheme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _staffOrgController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  bool _isUpdatingPassword = false;
  bool _isUpdatingProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _staffOrgController.dispose();
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar("Le nom d'utilisateur ne peut pas être vide. 👤");
      return;
    }

    setState(() => _isUpdatingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nom': newName,
      });
      _showSnackBar("Profil mis à jour avec succès ! ✨", isSuccess: true);
    } catch (e) {
      _showSnackBar("Impossible de mettre à jour le nom : $e");
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs de mot de passe. 🔑");
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Les nouveaux mots de passe ne correspondent pas. ❌");
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _showSnackBar("Mot de passe modifié avec succès ! 🎉", isSuccess: true);

      _oldPasswordController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Erreur Firebase : ${e.message}");
    } catch (e) {
      _showSnackBar("Erreur : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isSuccess ? BuckshotTheme.successColor.withOpacity(0.8) : theme.colorScheme.error,
        duration: const Duration(seconds: 5),
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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Gestion du compte',
          style: GoogleFonts.jura(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          if (_nameController.text.isEmpty && userData != null) {
            _nameController.text = userData['nom'] ?? '';
          }

          final role = userData?['role'] ?? 'USER';
          final bool isOrganizer = role == 'ORGANISATEUR';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // 1. BLOC PROFIL (PSEUDO)
                _buildNeonContainer(
                  context: context,
                  child: Column(
                    children: [
                      _buildTextField(
                        context: context,
                        label: "Nom d'utilisateur",
                        controller: _nameController,
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(
                        context: context,
                        text: _isUpdatingProfile ? "Enregistrement..." : "Enregistrer",
                        onPressed: _isUpdatingProfile ? null : _updateProfile,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. BLOC CHANGEMENT MOT DE PASSE
                if (isEmailProvider)
                  _buildNeonContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Changer le mot de passe",
                          style: GoogleFonts.jura(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          context: context,
                          label: "Ancien mot de passe",
                          controller: _oldPasswordController,
                          isPassword: true,
                          isObscured: _isOldPasswordObscured,
                          onToggleObscure: () => setState(() => _isOldPasswordObscured = !_isOldPasswordObscured),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context: context,
                          label: "Nouveau mot de passe",
                          controller: _passwordController,
                          isPassword: true,
                          isObscured: _isNewPasswordObscured,
                          onToggleObscure: () => setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context: context,
                          label: "Confirmer le nouveau mot de passe",
                          controller: _confirmPasswordController,
                          isPassword: true,
                          isObscured: _isConfirmPasswordObscured,
                          onToggleObscure: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                        ),
                        const SizedBox(height: 24),
                        _buildSaveButton(
                          context: context,
                          text: _isUpdatingPassword ? "Modification..." : "Modifier le mot de passe",
                          onPressed: _isUpdatingPassword ? null : _updatePassword,
                        ),
                      ],
                    ),
                  )
                else
                  _buildNeonContainer(
                    context: context,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Connecté via Google. Gestion du mot de passe indisponible. 🌐",
                        style: GoogleFonts.jura(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. BLOC ROLE DYNAMIQUE
                if (!isOrganizer)
                  _buildNeonContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Devenir organisateur"),
                        _buildTextField(context: context, label: "Nom de l'organisation", controller: _orgController),
                        const SizedBox(height: 16),
                        Center(child: _buildValiderButton(context: context, onPressed: () {})),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Divider(color: theme.colorScheme.background, thickness: 1),
                        ),

                        _buildSectionTitle("Devenir staff"),
                        _buildTextField(context: context, label: "Nom de l'organisation", controller: _staffOrgController),
                        const SizedBox(height: 16),
                        Center(child: _buildValiderButton(context: context, onPressed: () {})),
                      ],
                    ),
                  )
                else
                  _buildNeonContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Demandes d'accès"),
                        const SizedBox(height: 8),
                        _buildRequestItem(context, "Utilisateur 1", "Staff"),
                        _buildRequestItem(context, "Utilisateur 2", "Organisateur"),
                        _buildRequestItem(context, "Utilisateur 3", "Organisateur"),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // 4. SUPPRESSION DU COMPTE
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_remove_outlined, color: theme.colorScheme.error, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Supprimer mon compte",
                        style: GoogleFonts.jura(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5
                        ),
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

  // --- WIDGETS REUSABLES ADAPTÉS ---

  Widget _buildNeonContainer({required BuildContext context, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.jura(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscured = true,
    VoidCallback? onToggleObscure,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? isObscured : false,
          style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.background, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.background, width: 1),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
              onPressed: onToggleObscure,
            )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton({required BuildContext context, required String text, required VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_alt_outlined, color: theme.colorScheme.onPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.jura(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValiderButton({required BuildContext context, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      height: 38,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          "Valider",
          style: GoogleFonts.jura(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, String userName, String type) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.background, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    userName,
                    style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)
                ),
                Text(
                    type,
                    style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.check_rounded, color: BuckshotTheme.successColor, size: 24)
          ),
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 24)
          ),
        ],
      ),
    );
  }
}