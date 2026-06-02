import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoSection extends StatefulWidget {
  final String email;
  final String initialFirstName;
  final String initialLastName;
  final String userId;
  final Function(String, {bool isSuccess}) onShowSnackBar;

  const ProfileInfoSection({
    super.key,
    required this.email,
    required this.initialFirstName,
    required this.initialLastName,
    required this.userId,
    required this.onShowSnackBar,
  });

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isUpdatingProfile = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _firstNameController.text = widget.initialFirstName;
    _lastNameController.text = widget.initialLastName;
  }

  @override
  void didUpdateWidget(covariant ProfileInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_emailController.text.isEmpty && widget.email.isNotEmpty) {
      _emailController.text = widget.email;
    }
    if (_firstNameController.text.isEmpty && widget.initialFirstName.isNotEmpty) {
      _firstNameController.text = widget.initialFirstName;
    }
    if (_lastNameController.text.isEmpty && widget.initialLastName.isNotEmpty) {
      _lastNameController.text = widget.initialLastName;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();

    if (newFirstName.isEmpty || newLastName.isEmpty) {
      widget.onShowSnackBar("Le prénom et le nom ne peuvent pas être vides. 👤");
      return;
    }

    setState(() => _isUpdatingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'prenom': newFirstName,
        'nom': newLastName,
      });
      widget.onShowSnackBar("Profil mis à jour avec succès ! ✨", isSuccess: true);
    } catch (e) {
      widget.onShowSnackBar("Impossible de mettre à jour le profil : $e");
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
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
        children: [
          _buildTextField(context: context, label: "Email", controller: _emailController, readOnly: true),
          const SizedBox(height: 16),
          _buildTextField(context: context, label: "Prénom", controller: _firstNameController),
          const SizedBox(height: 16),
          _buildTextField(context: context, label: "Nom", controller: _lastNameController),
          const SizedBox(height: 24),
          _buildSaveButton(
            context: context,
            text: _isUpdatingProfile ? "Enregistrement..." : "Enregistrer",
            onPressed: _isUpdatingProfile ? null : _updateProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required BuildContext context, required String label, required TextEditingController controller, bool readOnly = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.jura(color: readOnly ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? theme.colorScheme.surface.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
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