import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/BuckshotTheme.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentOrgController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedOrgaId;
  String _selectedRole = 'STAFF';

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  bool _isUpdatingPassword = false;
  bool _isUpdatingProfile = false;
  bool _isSendingRequest = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentOrgController.dispose();
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();

    if (newFirstName.isEmpty || newLastName.isEmpty) {
      _showSnackBar("Le prénom et le nom ne peuvent pas être vides. 👤");
      return;
    }

    setState(() => _isUpdatingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
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

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedOrgaId == null) {
      _showSnackBar("Veuillez sélectionner une organisation. 🏢");
      return;
    }

    setState(() => _isSendingRequest = true);

    try {
      final orgaDoc = await FirebaseFirestore.instance.collection('organizers').doc(_selectedOrgaId).get();
      final orgaName = orgaDoc.data()?['nom'] ?? _selectedOrgaId;

      await FirebaseFirestore.instance.collection('demandes_organisation').doc(user.uid).set({
        'userId': user.uid,
        'userNom': "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        'orgaId': _selectedOrgaId,
        'orgaNom': orgaName,
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

  Future<void> _cancelRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('demandes_organisation').doc(user.uid).delete();
      _showSnackBar("Demande annulée.", isSuccess: true);
    } catch (e) {
      _showSnackBar("Impossible d'annuler la demande : $e");
    }
  }

  Future<void> _handleAcceptRequest(Map<String, dynamic> request) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final userDoc = FirebaseFirestore.instance.collection('users').doc(request['userId']);
      batch.update(userDoc, {
        'idOrganisateur': request['orgaId'],
        'role': request['roleDemande'],
      });

      final reqDoc = FirebaseFirestore.instance.collection('demandes_organisation').doc(request['userId']);
      batch.delete(reqDoc);

      await batch.commit();
      _showSnackBar("Demande acceptée avec succès !", isSuccess: true);
    } catch (e) {
      _showSnackBar("Erreur lors de la validation : $e");
    }
  }

  Future<void> _handleRejectRequest(String targetUserId) async {
    try {
      await FirebaseFirestore.instance.collection('demandes_organisation').doc(targetUserId).update({
        'status': 'REFUSE',
      });
      _showSnackBar("Demande refusée.");
    } catch (e) {
      _showSnackBar("Erreur : $e");
    }
  }

  Future<void> _leaveOrganisation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'idOrganisateur': '',
        'role': 'USER',
      });
      _showSnackBar("Vous avez quitté l'organisation. Retour au statut standard.", isSuccess: true);
    } catch (e) {
      _showSnackBar("Erreur lors de la sortie de l'organisation : $e");
    }
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isSuccess ? BuckshotTheme.successColor.withValues(alpha: 0.8) : theme.colorScheme.error,
        duration: const Duration(seconds: 4),
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

          if (_firstNameController.text.isEmpty && userData != null) {
            _firstNameController.text = userData['prenom'] ?? '';
          }
          if (_lastNameController.text.isEmpty && userData != null) {
            _lastNameController.text = userData['nom'] ?? '';
          }

          final role = userData?['role'] ?? 'USER';
          final String currentOrg = (userData?['idOrganisateur'] ?? '').toString().trim();

          if (_currentOrgController.text != currentOrg) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentOrgController.text = currentOrg;
                });
              }
            });
          }

          final bool hasOrganisation = (role == 'ORGANISATEUR' || role == 'STAFF') && currentOrg.isNotEmpty;
          final bool isOrganizer = role == 'ORGANISATEUR';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                _buildNeonContainer(
                  context: context,
                  child: Column(
                    children: [
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
                ),

                const SizedBox(height: 24),

                if (isEmailProvider)
                  _buildNeonContainer(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Changer le mot de passe", style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        "Connecté via un fournisseur externe. Gestion du mot de passe indisponible. 🌐",
                        style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                _buildNeonContainer(
                  context: context,
                  child: hasOrganisation
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(isOrganizer ? "Votre Organisation" : "Organisation rattachée"),
                      const SizedBox(height: 4),
                      Text("Rôle actuel : $role", style: GoogleFonts.jura(color: theme.colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('organizers').doc(currentOrg).get(),
                        builder: (context, orgSnap) {
                          String displayName = currentOrg;
                          if (orgSnap.hasData && orgSnap.data!.exists) {
                            displayName = (orgSnap.data!.data() as Map<String, dynamic>)['nom'] ?? currentOrg;
                          }
                          return _buildTextField(
                              context: context,
                              label: "Nom de la structure",
                              controller: TextEditingController(text: displayName),
                              readOnly: true
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
                          onPressed: _leaveOrganisation,
                          child: Text("Quitter l'organisation", style: GoogleFonts.jura(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      if (isOrganizer) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: theme.colorScheme.surface, thickness: 5),
                        ),
                        _buildSectionTitle("Demandes d'accès reçues"),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('demandes_organisation')
                              .where('orgaId', isEqualTo: currentOrg)
                              .snapshots(),
                          builder: (context, reqSnapshot) {
                            if (reqSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                            }

                            if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text("Aucune demande en attente pour votre structure. ☕", style: GoogleFonts.jura(color: Colors.grey, fontSize: 14)),
                              );
                            }

                            final docs = reqSnapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] == 'EN_ATTENTE';
                            }).toList();

                            if (docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text("Aucune demande en attente pour votre structure. ☕", style: GoogleFonts.jura(color: Colors.grey, fontSize: 14)),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              itemBuilder: (context, idx) {
                                final reqData = docs[idx].data() as Map<String, dynamic>;
                                return _buildRequestItem(context, reqData);
                              },
                            );
                          },
                        ),
                      ]
                    ],
                  )
                      : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('demandes_organisation').doc(user?.uid).snapshots(),
                    builder: (context, requestSnapshot) {
                      final reqDocExists = requestSnapshot.hasData && requestSnapshot.data!.exists;

                      if (reqDocExists) {
                        final reqData = requestSnapshot.data!.data() as Map<String, dynamic>;
                        final String status = reqData['status'] ?? 'EN_ATTENTE';
                        final String targetRole = reqData['roleDemande'] ?? 'STAFF';
                        final String targetOrgaName = reqData['orgaNom'] ?? reqData['orgaId'] ?? '';

                        Color statusColor = Colors.orange;
                        String statusText = "En attente de validation...";
                        if (status == 'REFUSE') {
                          statusColor = theme.colorScheme.error;
                          statusText = "Demande refusée par l'organisation.";
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Suivi de votre demande"),
                            const SizedBox(height: 14),
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
                                  Text("Structure : $targetOrgaName", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Poste demandé : $targetRole", style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(status == 'REFUSE' ? Icons.gpp_bad_outlined : Icons.hourglass_empty_rounded, color: statusColor, size: 20),
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
                                onPressed: _cancelRequest,
                                child: Text(status == 'REFUSE' ? "Nouvelle demande" : "Annuler la demande", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('organizers').snapshots(),
                        builder: (context, organizersSnapshot) {
                          if (!organizersSnapshot.hasData) return const LinearProgressIndicator();

                          final orgDocs = organizersSnapshot.data!.docs;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("Rejoindre une structure"),
                              const SizedBox(height: 16),

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
                                items: orgDocs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(data['nom'] ?? doc.id, overflow: TextOverflow.ellipsis),
                                  );
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

                              _buildSaveButton(
                                context: context,
                                text: _isSendingRequest ? "Envoi..." : "Envoyer ma demande",
                                onPressed: _isSendingRequest ? null : _submitRequest,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

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

  Widget _buildNeonContainer({required BuildContext context, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 25, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.jura(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscured = true,
    bool readOnly = false,
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
          readOnly: readOnly,
          style: GoogleFonts.jura(color: readOnly ? Colors.grey[500] : theme.colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? theme.colorScheme.surface.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.surface, width: 1)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
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
                Icon(Icons.rocket_launch_outlined, color: theme.colorScheme.onPrimary, size: 24),
                const SizedBox(width: 12),
                Text(text, style: GoogleFonts.jura(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, dynamic> request) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.surface, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request['userNom'] ?? 'Utilisateur Inconnu', style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Poste : ${request['roleDemande']}", style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _handleAcceptRequest(request),
            icon: Icon(Icons.check_rounded, color: BuckshotTheme.successColor, size: 24),
          ),
          IconButton(
            onPressed: () => _handleRejectRequest(request['userId']),
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 24),
          ),
        ],
      ),
    );
  }
}