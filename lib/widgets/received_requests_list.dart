import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:buckshot/BuckshotTheme.dart';
import '../models/demande_orga_model.dart';

class ReceivedRequestsList extends StatelessWidget {
  final String currentOrg;
  final Function(String, {bool isSuccess}) onShowSnackBar;

  const ReceivedRequestsList({
    super.key,
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