import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedFirebaseDatabase() async {
  final firestore = FirebaseFirestore.instance;

  print("DÉBUT DE L'INSERTION AUTOMATIQUE...");

  // 1. Insertion de l'utilisateur (Toi !)
  String userId = "test_user_jules";
  await firestore.collection('users').doc(userId).set({
    'nom': 'Dupont',
    'prenom': 'Jules',
    'email': 'jules.insa@uphf.fr',
    'role': 'ORGANISATEUR',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Insertion du groupe organisateur
  String organizerId = "orga_bde_insa";
  await firestore.collection('organizers').doc(organizerId).set({
    'nom': 'BDE INSA HDF',
    'urlLogo': 'https://example.com/logo_bde.png',
  });

  // 3. Insertion de la soirée (Événement)
  String eventId = "event_gala_2026";
  await firestore.collection('events').doc(eventId).set({
    'nom': 'Gala INSA 2026',
    'description': 'Le grand gala annuel de l\'INSA Hauts-de-France ! 🍾',
    'lieu': 'Les Tertiales, Valenciennes',
    'capaciteMax': 500,
    'placesRestantes': 500,
    'dateHeureEvent': Timestamp.fromDate(DateTime(2026, 06, 05, 20, 00)),
    'dateOuvertureBilletterie': Timestamp.fromDate(DateTime(2026, 05, 20, 18, 00)),
    'dateFermetureBilletterie': Timestamp.fromDate(DateTime(2026, 06, 04, 23, 59)),
    'idOrganisateur': organizerId,
  });

  // 4. Insertion du billet de test (Celui à scanner)
  String ticketId = "ticket_gala_jules";
  await firestore.collection('tickets').doc(ticketId).set({
    'idUtilisateur': userId,
    'idEvenement': eventId,
    'statut': 'VALIDE',
    'timestampInscription': FieldValue.serverTimestamp(),
    'idToken': 'buckshot_gala_jules_xyz123',
  });

  print("✅ INSERTION TERMINÉE ! Rafraîchis ta console Firebase !");
}