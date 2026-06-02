import 'package:buckshot/models/role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String idUtilisateur;
  final String nom;
  final String prenom;
  final String email;
  final Role role;
  final DateTime createdAt;

  EventModel({
    required this.idUtilisateur,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  // Convertit un document Firestore en objet Dart exploitable
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      idUtilisateur: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      role: Role.values.firstWhere(
        (r) => r.name == data['role'], 
        orElse: () => Role.etudiant, 
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role.name, 
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}