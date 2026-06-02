import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordSection extends StatefulWidget {
  final Function(String, {bool isSuccess}) onShowSnackBar;

  const PasswordSection({super.key, required this.onShowSnackBar});

  @override
  State<PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<PasswordSection> {
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isUpdatingPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      widget.onShowSnackBar("Veuillez remplir tous les champs de mot de passe. 🔑");
      return;
    }

    if (newPassword != confirmPassword) {
      widget.onShowSnackBar("Les nouveaux mots de passe ne correspondent pas. ❌");
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      widget.onShowSnackBar("Mot de passe modifié avec succès ! 🎉", isSuccess: true);
      _oldPasswordController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      widget.onShowSnackBar("Erreur Firebase : ${e.message}");
    } catch (e) {
      widget.onShowSnackBar("Erreur : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 25, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Changer le mot de passe", style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(
            context: context,
            label: "Ancien mot de passe",
            controller: _oldPasswordController,
            isObscured: _isOldPasswordObscured,
            onToggleObscure: () => setState(() => _isOldPasswordObscured = !_isOldPasswordObscured),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context: context,
            label: "Nouveau mot de passe",
            controller: _passwordController,
            isObscured: _isNewPasswordObscured,
            onToggleObscure: () => setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context: context,
            label: "Confirmer le nouveau mot de passe",
            controller: _confirmPasswordController,
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
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleObscure,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscured,
          style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            suffixIcon: IconButton(
              icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
              onPressed: onToggleObscure,
            ),
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
          disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: theme.colorScheme.onPrimary, size: 24),
                const SizedBox(width: 12),
                Text(text, style: GoogleFonts.jura(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}