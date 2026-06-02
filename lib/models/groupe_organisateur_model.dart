import 'package:cloud_firestore/cloud_firestore.dart';

class GroupeOrganisateur {
  final String idOrganisation;
  final String nom;
  final String urlLogo;

  GroupeOrganisateur({
    required this.idOrganisation,
    required this.nom,
    required this.urlLogo,
  });

  // Convertit un document Firestore en objet Dart exploitable
  factory GroupeOrganisateur.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupeOrganisateur(
      idOrganisation: doc.id,
      nom: data['nom'] ?? '',
      urlLogo: data['urlLogo'] ?? 'assets/markdown/BuckshotLogoShort.png',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'urlLogo': urlLogo,
    };
  }
}