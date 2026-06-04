import 'package:buckshot/models/billet_inscription_model.dart';
import 'package:buckshot/models/event_model.dart';
import 'package:buckshot/models/groupe_organisateur_model.dart';
import 'package:buckshot/models/statut_billet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventModel', () {
    test('toFirestore expose les champs attendus par la collection events', () {
      final start = DateTime(2026, 6, 5, 20);
      final end = DateTime(2026, 6, 6, 2);
      final open = DateTime(2026, 6, 1, 18);
      final close = DateTime(2026, 6, 5, 18);

      final event = EventModel(
        id: 'event_gala',
        nom: 'Gala Buckshot',
        description: 'Soiree annuelle',
        lieu: 'Valenciennes',
        capaciteMax: 500,
        idOrganisateur: 'orga_bde',
        placesRestantes: 123,
        dateHeureEvent: start,
        dateFinEvent: end,
        dateOuvertureBilletterie: open,
        dateFermetureBilletterie: close,
        image: 'base64-image',
      );

      final data = event.toFirestore();

      expect(data, containsPair('nom', 'Gala Buckshot'));
      expect(data, containsPair('description', 'Soiree annuelle'));
      expect(data, containsPair('lieu', 'Valenciennes'));
      expect(data, containsPair('idOrganisateur', 'orga_bde'));
      expect(data, containsPair('capaciteMax', 500));
      expect(data, containsPair('placesRestantes', 123));
      expect(data, containsPair('dateHeureEvent', start));
      expect(data, containsPair('dateFinEvent', end));
      expect(data, containsPair('dateOuvertureBilletterie', open));
      expect(data, containsPair('dateFermetureBilletterie', close));
      expect(data, containsPair('image', 'base64-image'));
    });
  });

  group('GroupeOrganisateur', () {
    test('toFirestore serialise le nom et le logo', () {
      final organizer = GroupeOrganisateur(
        idOrganisation: 'orga_bde',
        nom: 'BDE INSA HDF',
        urlLogo: 'https://example.com/logo.png',
      );

      expect(organizer.toFirestore(), {
        'nom': 'BDE INSA HDF',
        'urlLogo': 'https://example.com/logo.png',
      });
    });
  });

  group('BilletInscriptionModel', () {
    test('toFirestore convertit la date en Timestamp et le statut en chaine', () {
      final createdAt = DateTime(2026, 6, 5, 19, 30);
      final billet = BilletInscriptionModel(
        idUtilisateur: 'user_1',
        idEvenement: 'event_1',
        timestampInscription: createdAt,
        statutBillet: StatutBillet.VALIDE,
      );

      final data = billet.toFirestore();

      expect(data['idUtilisateur'], 'user_1');
      expect(data['idEvenement'], 'event_1');
      expect(data['statutBillet'], 'VALIDE');
      expect(data['timestampInscription'], isA<Timestamp>());
      expect((data['timestampInscription'] as Timestamp).toDate(), createdAt);
    });
  });
}
