import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String nom;
  final String description;
  final String lieu;
  final String idOrganisateur;
  final int capaciteMax;
  final int placesRestantes;
  final DateTime dateHeureEvent;
  final DateTime dateFinEvent;
  final DateTime dateOuvertureBilletterie;
  final DateTime dateFermetureBilletterie;

  EventModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.lieu,
    required this.capaciteMax,
    required this.idOrganisateur,
    required this.placesRestantes,
    required this.dateHeureEvent,
    required this.dateFinEvent,
    required this.dateOuvertureBilletterie,
    required this.dateFermetureBilletterie,
  });

  // Convertit un document Firestore en objet Dart exploitable
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      lieu: data['lieu'] ?? "",
      idOrganisateur: data['idOrganisateur'] ?? "",
      capaciteMax: data['capaciteMax'] ?? 0,
      placesRestantes: data['placesRestantes'] ?? 0,
      dateHeureEvent: (data['dateHeureEvent'] as Timestamp).toDate(),
      dateFinEvent: (data['dateFinEvent'] as Timestamp).toDate(),
      dateFermetureBilletterie: (data['dateFinEvent'] as Timestamp).toDate(), //ntm c pa ds le bon sens
      dateOuvertureBilletterie: (data['dateOuvertureBilletterie'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'description': description,
      'lieu': lieu,
      'idOrganisateur': idOrganisateur,
      'capaciteMax': capaciteMax,
      'placesRestantes': placesRestantes,
      'dateHeureEvent': dateHeureEvent,
      'dateFinEvent': dateFinEvent,
      'dateFermetureBilletterie': dateFermetureBilletterie,
      'dateOuvertureBilletterie': dateOuvertureBilletterie,
    };
  }
}