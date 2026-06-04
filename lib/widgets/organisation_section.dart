import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/buckshot_theme.dart';
import '../models/groupe_organisateur_model.dart';
import '../models/demande_orga_model.dart';

class OrganisationSection extends StatefulWidget {
  final String role;
  final String currentOrg;
  final String userId;
  final String userFullName;
  final Function(String, {bool isSuccess}) onShowSnackBar;

  const OrganisationSection({
    super.key,
    required this.role,
    required this.currentOrg,
    required this.userId,
    required this.userFullName,
    required this.onShowSnackBar,
  });

  @override
  State<OrganisationSection> createState() => _OrganisationSectionState();
}

class _OrganisationSectionState extends State<OrganisationSection> {
  String? _selectedOrgaId;
  String _selectedRole = 'STAFF';
  bool _isSendingRequest = false;

  Future<void> _submitRequest() async {
    if (_selectedOrgaId == null) {
      widget.onShowSnackBar("Veuillez sélectionner une organisation. 🏢");
      return;
    }
    setState(() => _isSendingRequest = true);
    try {
      final orgaDoc = await FirebaseFirestore.instance.collection('organizers').doc(_selectedOrgaId).get();
      final organization = GroupeOrganisateur.fromFirestore(orgaDoc);

      await FirebaseFirestore.instance.collection('demandes_organisation').doc(widget.userId).set({
        'userId': widget.userId,
        'userNom': widget.userFullName,
        'orgaId': _selectedOrgaId,
        'orgaNom': organization.nom,
        'roleDemande': _selectedRole,
        'status': 'EN_ATTENTE',
        'createdAt': FieldValue.serverTimestamp(),
      });
      widget.onShowSnackBar("Demande envoyée avec succès ! 🚀", isSuccess: true);
    } catch (e) {
      widget.onShowSnackBar("Erreur lors de l'envoi de la demande : $e");
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _cancelRequest() async {
    try {
      await FirebaseFirestore.instance.collection('demandes_organisation').doc(widget.userId).delete();
      widget.onShowSnackBar("Demande annulée.", isSuccess: true);
    } catch (e) {
      widget.onShowSnackBar("Impossible d'annuler la demande : $e");
    }
  }

  Future<void> _leaveOrganisation() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'idOrganisateur': '',
        'role': 'USER',
      });
      widget.onShowSnackBar("Vous avez quitté l'organisation. Retour au statut standard.", isSuccess: true);
    } catch (e) {
      widget.onShowSnackBar("Erreur lors de la sortie de l'organisation : $e");
    }
  }

  void _showLeaveConfirmationDialog(BuildContext context) {
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
                _leaveOrganisation();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasOrganisation = (widget.role == 'ORGANISATEUR' || widget.role == 'STAFF') && widget.currentOrg.isNotEmpty;
    final bool isOrganizer = widget.role == 'ORGANISATEUR';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 25)],
      ),
      child: hasOrganisation
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(isOrganizer ? "Votre Organisation" : "Organisation rattachée"),
                const SizedBox(height: 4),
                Text("Rôle actuel : ${widget.role}", style: GoogleFonts.jura(color: theme.colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('organizers').doc(widget.currentOrg).get(),
                  builder: (context, orgSnap) {
                    String displayName = widget.currentOrg;
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
                    onPressed: () => _showLeaveConfirmationDialog(context),
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
                  _ReceivedRequestsList(currentOrg: widget.currentOrg, onShowSnackBar: widget.onShowSnackBar),
                ]
              ],
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('demandes_organisation').doc(widget.userId).snapshots(),
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
                          onPressed: _cancelRequest,
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
                            onPressed: _isSendingRequest ? null : _submitRequest,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.jura(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _ReceivedRequestsList extends StatelessWidget {
  final String currentOrg;
  final Function(String, {bool isSuccess}) onShowSnackBar;

  const _ReceivedRequestsList({
    required this.currentOrg,
    required this.onShowSnackBar,
  });

  Future<void> _handleAcceptRequest(DemandeOrgaModel request) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userDoc = FirebaseFirestore.instance.collection('users').doc(request.userId);
      
      batch.update(userDoc, {
        'idOrganisateur': request.orgaId,
        'role': request.roleDemande,
      });

      final reqDoc = FirebaseFirestore.instance.collection('demandes_organisation').doc(request.userId);
      batch.delete(reqDoc);

      await batch.commit();
      onShowSnackBar("Demande acceptée avec succès !", isSuccess: true);
    } catch (e) {
      onShowSnackBar("Erreur lors de la validation : $e");
    }
  }

  Future<void> _handleRejectRequest(String targetUserId) async {
    try {
      await FirebaseFirestore.instance.collection('demandes_organisation').doc(targetUserId).update({'status': 'REFUSE'});
      onShowSnackBar("Demande refusée.");
    } catch (e) {
      onShowSnackBar("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('demandes_organisation')
          .where('orgaId', isEqualTo: currentOrg)
          .snapshots(),
      builder: (context, reqSnapshot) {
        if (reqSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }

        final docs = reqSnapshot.data?.docs.map((doc) => DemandeOrgaModel.fromFirestore(doc)).where((req) => req.status == 'EN_ATTENTE').toList() ?? [];

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
            final request = docs[idx];
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
                        Text(request.userNom, style: GoogleFonts.jura(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("Poste : ${request.roleDemande}", style: GoogleFonts.jura(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleAcceptRequest(request),
                    icon: const Icon(Icons.check_rounded, color: BuckshotTheme.successColor, size: 24),
                  ),
                  IconButton(
                    onPressed: () => _handleRejectRequest(request.userId),
                    icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 24),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}