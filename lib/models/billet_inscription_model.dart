import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buckshot/models/statut_billet.dart';

class BilletInscriptionModel {
  final String idUtilisateur;
  final String idEvenement;
  final DateTime timestampInscription;
  final StatutBillet statutBillet;

  BilletInscriptionModel({
    required this.idUtilisateur,
    required this.idEvenement,
    required this.timestampInscription,
    required this.statutBillet,
  });

  // Convertit un document Firestore en objet Dart exploitable
  factory BilletInscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BilletInscriptionModel(
      idUtilisateur: data['idUtilisateur'] ?? '',
      idEvenement: data['idEvenement'] ?? '',
      timestampInscription: (data['timestampInscription'] as Timestamp).toDate(),
      statutBillet: StatutBillet.values.firstWhere(
        (s) => s.name == data['statutBillet'],
        orElse: () => StatutBillet.ANNULE, //Annuler le billet si le statut n'est pas reconnu
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idUtilisateur': idUtilisateur,
      'idEvenement': idEvenement,
      'timestampInscription': Timestamp.fromDate(timestampInscription),
      'statutBillet': statutBillet.name,
    };
  }
}