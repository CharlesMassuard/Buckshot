import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/buckshot_theme.dart';
import 'login_view.dart';
import '../models/groupe_organisateur_model.dart';
import '../models/demande_orga_model.dart';
import '../widgets/received_requests_list.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isUpdatingProfile = false;

  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isUpdatingPassword = false;

  String? _selectedOrgaId;
  String _selectedRole = 'STAFF';
  bool _isSendingRequest = false;

  late TapGestureRecognizer _mentionsLegalesRecognizer;
  late TapGestureRecognizer _politiqueConfidentialiteRecognizer;

  @override
  void initState() {
    super.initState();
    _mentionsLegalesRecognizer = TapGestureRecognizer()
      ..onTap = () => _showMarkdownDialog(context, 'Mentions légales', 'assets/markdown/mentions_legales.md');

    _politiqueConfidentialiteRecognizer = TapGestureRecognizer()
      ..onTap = () => _showMarkdownDialog(context, 'Politique de confidentialité', 'assets/markdown/privacy_politique.md');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _oldPasswordController.dispose();
    _confirmPasswordController.dispose();

    _mentionsLegalesRecognizer.dispose();
    _politiqueConfidentialiteRecognizer.dispose();
    super.dispose();
  }

  void _showMarkdownDialog(BuildContext context, String title, String assetPath) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<String>(
              future: rootBundle.loadString(assetPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                }
                if (snapshot.hasError) {
                  return const Text('Erreur lors du chargement du fichier', style: TextStyle(color: Colors.white));
                }
                
                return SingleChildScrollView(
                  child: MarkdownBody(
                    data: snapshot.data ?? 'Fichier vide',
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                      h1: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 20),
                      h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      listBullet: const TextStyle(color: Color(0xFF9D4EDD)),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer', style: TextStyle(color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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

  Future<void> _updateProfile(String userId) async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();

    if (newFirstName.isEmpty || newLastName.isEmpty) {
      _showSnackBar("Le prénom et le nom ne peuvent pas être vides. 👤");
      return;
    }

    setState(() => _isUpdatingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'prenom': newFirstName,
        'nom': newLastName,
      });
      _showSnackBar("Profil mis à jour avec succès ! ✨", isSuccess: true);
    } catch (e) {
      _showSnackBar("Impossible de mettre à jour le profil : $e");
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
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
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

  Future<void> _submitRequest(String userId, String userFullName) async {
    if (_selectedOrgaId == null) {
      _showSnackBar("Veuillez sélectionner une organisation. 🏢");
      return;
    }
    setState(() => _isSendingRequest = true);
    try {
      final orgaDoc = await FirebaseFirestore.instance.collection('organizers').doc(_selectedOrgaId).get();
      final organization = GroupeOrganisateur.fromFirestore(orgaDoc);

      await FirebaseFirestore.instance.collection('demandes_organisation').doc(userId).set({
        'userId': userId,
        'userNom': userFullName,
        'orgaId': _selectedOrgaId,
        'orgaNom': organization.nom,
        'roleDemande': _selectedRole,
        'status': 'EN_ATTENTE',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar("Demande envoyée avec succès ! 🚀", isSuccess: true);
    } catch (e) {
      _showSnackBar("Erreur lors de l'envoi de la demande : $e");
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _cancelRequest(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('demandes_organisation').doc(userId).delete();
      _showSnackBar("Demande annulée.", isSuccess: true);
    } catch (e) {
      _showSnackBar("Impossible d'annuler la demande : $e");
    }
  }

  Future<void> _leaveOrganisation(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'idOrganisateur': '',
        'role': 'USER',
      });
      _showSnackBar("Vous avez quitté l'organisation. Retour au statut standard.", isSuccess: true);
    } catch (e) {
      _showSnackBar("Erreur lors de la sortie de l'organisation : $e");
    }
  }

  Future<void> _removeStaffMember(String staffUserId, String staffName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(staffUserId).update({
        'idOrganisateur': '',
        'role': 'USER',
      });
      _showSnackBar("$staffName a été retiré de la structure avec succès. 🫡", isSuccess: true);
    } catch (e) {
      _showSnackBar("Impossible de retirer ce membre : $e");
    }
  }

  void _showLeaveConfirmationDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Quitter l'organisation",
            style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Êtes-vous sûr de vouloir quitter cette organisation ? Vos accès privilégiés seront révoqués.",
            style: GoogleFonts.jura(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Annuler", style: GoogleFonts.jura(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.pop(dialogContext);
                _leaveOrganisation(userId);
              },
              child: Text(
                "Quitter",
                style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveStaffDialog(BuildContext context, String staffUserId, String staffName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Retirer de la structure",
            style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Voulez-vous vraiment exclure $staffName de votre organisation ? Il perdra ses accès d'administration.",
            style: GoogleFonts.jura(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Annuler", style: GoogleFonts.jura(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.pop(dialogContext);
                _removeStaffMember(staffUserId, staffName);
              },
              child: Text(
                "Retirer",
                style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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

  Widget _buildTextField({required BuildContext context, required String label, required TextEditingController controller, bool readOnly = false, bool isObscured = false, VoidCallback? onToggleObscure}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isObscured,
          style: GoogleFonts.jura(color: readOnly ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? theme.colorScheme.surface.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: onToggleObscure != null
                ? IconButton(
              icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
              onPressed: onToggleObscure,
            )
                : null,
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

  Widget _buildCategoryCategoryTile({required BuildContext context, required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Icon(icon, color: theme.colorScheme.secondary, size: 24),
          title: Text(
            title,
            style: GoogleFonts.jura(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          iconColor: theme.colorScheme.secondary,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.all(20).copyWith(top: 0),
          children: children,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Text.rich(
      TextSpan(
        text: 'En utilisant notre application, vous acceptez nos \n',
        style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 11, height: 1.4),
        children: [
          TextSpan(
            text: 'mentions légales',
            recognizer: _mentionsLegalesRecognizer,
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
          ),
          const TextSpan(text: ' et notre '),
          TextSpan(
            text: 'politique de confidentialité',
            recognizer: _politiqueConfidentialiteRecognizer,
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
          ),
        ],
      ),
      textAlign: TextAlign.center,
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

          if (_emailController.text.isEmpty) _emailController.text = email;
          if (_firstNameController.text.isEmpty) _firstNameController.text = prenom;
          if (_lastNameController.text.isEmpty) _lastNameController.text = nom;

          final bool hasOrganisation = (role == 'ORGANISATEUR' || role == 'STAFF') && currentOrg.isNotEmpty;
          final bool isOrganizer = role == 'ORGANISATEUR';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [

                _buildCategoryCategoryTile(
                  context: context,
                  title: "Informations personnelles",
                  icon: Icons.person_outline_rounded,
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
                      onPressed: _isUpdatingProfile ? null : () => _updateProfile(user?.uid ?? ''),
                    ),
                  ],
                ),

                if (isEmailProvider)
                  _buildCategoryCategoryTile(
                    context: context,
                    title: "Sécurité & Mot de passe",
                    icon: Icons.lock_outline_rounded,
                    children: [
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
                  )
                else
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
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

                _buildCategoryCategoryTile(
                  context: context,
                  title: hasOrganisation ? "Votre Organisation" : "Rejoindre une structure",
                  icon: Icons.corporate_fare_rounded,
                  children: [
                    hasOrganisation
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rôle actuel : $role", style: GoogleFonts.jura(color: theme.colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('organizers').doc(currentOrg).get(),
                          builder: (context, orgSnap) {
                            String displayName = currentOrg;
                            if (orgSnap.hasData && orgSnap.data!.exists) {
                              final organization = GroupeOrganisateur.fromFirestore(orgSnap.data!);
                              displayName = organization.nom;
                            }
                            return TextField(
                              controller: TextEditingController(text: displayName),
                              readOnly: true,
                              style: GoogleFonts.jura(color: Colors.grey[500]),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                                labelText: "Nom de la structure",
                                labelStyle: GoogleFonts.jura(color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showLeaveConfirmationDialog(context, user?.uid ?? ''),
                            child: Text("Quitter l'organisation", style: GoogleFonts.jura(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (isOrganizer) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(color: theme.colorScheme.surfaceContainerHighest, thickness: 1),
                          ),
                          Text("Demandes d'accès reçues", style: GoogleFonts.jura(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ReceivedRequestsList(currentOrg: currentOrg, onShowSnackBar: _showSnackBar),
                        ]
                      ],
                    )
                        : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('demandes_organisation').doc(user?.uid).snapshots(),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.hasData && requestSnapshot.data!.exists) {
                          final reqData = DemandeOrgaModel.fromFirestore(requestSnapshot.data!);

                          Color statusColor = Colors.orange;
                          String statusText = "En attente de validation...";
                          if (reqData.status == 'REFUSE') {
                            statusColor = theme.colorScheme.error;
                            statusText = "Demande refusée par l'organisation.";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Structure : ${reqData.orgaNom}", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text("Poste demandé : ${reqData.roleDemande}", style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 13)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(reqData.status == 'REFUSE' ? Icons.gpp_bad_outlined : Icons.hourglass_empty_rounded, color: statusColor, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(statusText, style: GoogleFonts.jura(color: statusColor, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                                  onPressed: () => _cancelRequest(user?.uid ?? ''),
                                  child: Text(reqData.status == 'REFUSE' ? "Nouvelle demande" : "Annuler la demande", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('organizers').snapshots(),
                          builder: (context, organizersSnapshot) {
                            if (!organizersSnapshot.hasData) return const LinearProgressIndicator();

                            final organizations = organizersSnapshot.data!.docs.map((doc) => GroupeOrganisateur.fromFirestore(doc)).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  dropdownColor: theme.colorScheme.surface,
                                  initialValue: _selectedOrgaId,
                                  isExpanded: true,
                                  style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: "Sélectionnez l'organisation",
                                    labelStyle: GoogleFonts.jura(color: Colors.grey),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: organizations.map((org) {
                                    return DropdownMenuItem<String>(value: org.idOrganisation, child: Text(org.nom, overflow: TextOverflow.ellipsis));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedOrgaId = val),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  dropdownColor: theme.colorScheme.surface,
                                  initialValue: _selectedRole,
                                  isExpanded: true,
                                  style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: "Poste souhaité",
                                    labelStyle: GoogleFonts.jura(color: Colors.grey),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'STAFF', child: Text("Intégrer le Staff")),
                                    DropdownMenuItem(value: 'ORGANISATEUR', child: Text("Co-Organisateur")),
                                  ],
                                  onChanged: (val) => setState(() => _selectedRole = val ?? 'STAFF'),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                                    onPressed: _isSendingRequest ? null : () => _submitRequest(user?.uid ?? '', "$prenom $nom"),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 24),
                                        const SizedBox(width: 12),
                                        Text(_isSendingRequest ? "Envoi..." : "Envoyer ma demande", style: GoogleFonts.jura(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                if (isOrganizer && currentOrg.isNotEmpty)
                  _buildCategoryCategoryTile(
                    context: context,
                    title: "Gestion des Staffs",
                    icon: Icons.people_alt_outlined,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('idOrganisateur', isEqualTo: currentOrg)
                            .snapshots(),
                        builder: (context, staffSnapshot) {
                          if (staffSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final staffDocs = staffSnapshot.data?.docs ?? [];
                          
                          final filteredStaffDocs = staffDocs.where((doc) => doc.id != user?.uid).toList();

                          if (filteredStaffDocs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "Aucun autre membre dans votre structure pour le moment. 👥",
                                style: GoogleFonts.jura(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                            );
                          }

                          filteredStaffDocs.sort((a, b) {
                            final roleA = (a.data() as Map<String, dynamic>)['role'] ?? 'STAFF';
                            final roleB = (b.data() as Map<String, dynamic>)['role'] ?? 'STAFF';
                            if (roleA == 'ORGANISATEUR' && roleB != 'ORGANISATEUR') return -1;
                            if (roleA != 'ORGANISATEUR' && roleB == 'ORGANISATEUR') return 1;
                            return 0;
                          });

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredStaffDocs.length,
                            separatorBuilder: (context, index) => Divider(color: theme.colorScheme.surfaceContainerHighest, height: 1),
                            itemBuilder: (context, index) {
                              final staffData = filteredStaffDocs[index].data() as Map<String, dynamic>;
                              final String sPrenom = staffData['prenom'] ?? '';
                              final String sNom = staffData['nom'] ?? '';
                              final String sEmail = staffData['email'] ?? '';
                              final String sRole = staffData['role'] ?? 'STAFF';
                              final String staffId = filteredStaffDocs[index].id;
                              final String fullName = "$sPrenom $sNom";

                              final bool isMemberOrganizer = sRole == 'ORGANISATEUR';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fullName, 
                                        style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isMemberOrganizer 
                                            ? const Color(0xFF4EA8DE).withValues(alpha: 0.15) 
                                            : const Color(0xFF9D4EDD).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isMemberOrganizer ? const Color(0xFF4EA8DE) : const Color(0xFF9D4EDD),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isMemberOrganizer ? "Organisateur" : "Staff",
                                        style: GoogleFonts.jura(
                                          color: isMemberOrganizer ? const Color(0xFF4EA8DE) : const Color(0xFFB776EE),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(sEmail, style: GoogleFonts.jura(color: Colors.grey, fontSize: 13)),
                                trailing: isMemberOrganizer
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.redAccent, size: 22),
                                        tooltip: "Retirer de la structure",
                                        onPressed: () => _showRemoveStaffDialog(context, staffId, fullName),
                                      ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 40),

                _buildFooter(theme),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}