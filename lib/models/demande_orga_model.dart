import 'package:cloud_firestore/cloud_firestore.dart';

class DemandeOrgaModel {
  final String userId;
  final String userNom;
  final String orgaId;
  final String orgaNom;
  final String roleDemande;
  final String status;

  DemandeOrgaModel({
    required this.userId,
    required this.userNom,
    required this.orgaId,
    required this.orgaNom,
    required this.roleDemande,
    required this.status,
  });

  factory DemandeOrgaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DemandeOrgaModel(
      userId: doc.id,
      userNom: data['userNom'] ?? 'Utilisateur Inconnu',
      orgaId: data['orgaId'] ?? '',
      orgaNom: data['orgaNom'] ?? '',
      roleDemande: data['roleDemande'] ?? 'STAFF',
      status: data['status'] ?? 'EN_ATTENTE',
    );
  }
}