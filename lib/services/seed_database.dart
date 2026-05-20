import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedFirebaseDatabase() async {
  final firestore = FirebaseFirestore.instance;

  print("🔍 Vérification des données existantes (serveur uniquement)...");

  try {
    // Force la lecture depuis le serveur, jamais depuis le cache local
    final existingUser = await firestore
        .collection('users')
        .doc('test_user_jules')
        .get(const GetOptions(source: Source.server));

    print("DÉBUT DE L'INSERTION AUTOMATIQUE...");

    // 1. Insertion de l'utilisateur
    String userId = "test_user_jules";
    await firestore.collection('users').doc(userId).set({
      'nom': 'Dupont',
      'prenom': 'Jules',
      'email': 'jules.insa@uphf.fr',
      'role': 'ORGANISATEUR',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("✅ [1/4] User inséré : $userId");

    // 2. Insertion du groupe organisateur
    String organizerId = "orga_bde_insa";
    await firestore.collection('organizers').doc(organizerId).set({
      'nom': 'BDE INSA HDF',
      'urlLogo': 'https://example.com/logo_bde.png',
    });
    print("✅ [2/4] Organizer inséré : $organizerId");

    // 3. Insertion de la soirée (Événement)
    String eventId = "event_gala_2026";
    await firestore.collection('events').doc(eventId).set({
      'nom': 'Gala INSA 2026',
      'description': 'Le grand gala annuel de l\'INSA Hauts-de-France ! 🍾',
      'lieu': 'Les Tertiales, Valenciennes',
      'capaciteMax': 500,
      'placesRestantes': 500,
      'dateHeureEvent': Timestamp.fromDate(DateTime(2026, 06, 05, 20, 00)),
      'dateOuvertureBilletterie':
          Timestamp.fromDate(DateTime(2026, 05, 20, 18, 00)),
      'dateFermetureBilletterie':
          Timestamp.fromDate(DateTime(2026, 06, 04, 23, 59)),
      'idOrganisateur': organizerId,
    });
    print("✅ [3/4] Event inséré : $eventId");

    // 4. Insertion du billet de test
    String ticketId = "ticket_gala_jules";
    await firestore.collection('tickets').doc(ticketId).set({
      'idUtilisateur': userId,
      'idEvenement': eventId,
      'statut': 'VALIDE',
      'timestampInscription': FieldValue.serverTimestamp(),
      'idToken': 'buckshot_gala_jules_xyz123',
    });
    print("✅ [4/4] Ticket inséré : $ticketId");

    print("🎉 INSERTION TERMINÉE ! Rafraîchis ta console Firebase !");
  } catch (e, stackTrace) {
    print("❌ ERREUR SEED : $e");
    print("📋 Stack trace : $stackTrace");
  }
}