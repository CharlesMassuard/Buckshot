import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String nom;
  final String description;
  final String lieu;
  final int capaciteMax;
  final int placesRestantes;
  final DateTime dateHeureEvent;
  final DateTime dateOuvertureBilletterie;

  EventModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.lieu,
    required this.capaciteMax,
    required this.placesRestantes,
    required this.dateHeureEvent,
    required this.dateOuvertureBilletterie,
  });

  // Convertit un document Firestore en objet Dart exploitable
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      lieu: data['lieu'] ?? '',
      capaciteMax: data['capaciteMax'] ?? 0,
      placesRestantes: data['placesRestantes'] ?? 0,
      dateHeureEvent: (data['dateHeureEvent'] as Timestamp).toDate(),
      dateOuvertureBilletterie: (data['dateOuvertureBilletterie'] as Timestamp).toDate(),
    );
  }
}