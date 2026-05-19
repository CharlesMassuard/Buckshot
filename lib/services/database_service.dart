import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Flux de données (Stream) qui écoute les modifications de Firebase en temps réel
  Stream<List<EventModel>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Fonction appelée par le scanner pour passer un billet en "SCANNE"
  Future<bool> validerBillet(String tokenScanne) async {
    try {
      var query = await _db.collection('tickets').where('idToken', isEqualTo: tokenScanne).get();

      if (query.docs.isNotEmpty) {
        String ticketId = query.docs.first.id;
        String statutActuel = query.docs.first.data()['statut'] ?? 'VALIDE';

        if (statutActuel == 'SCANNE') {
          return false; // Billet déjà scanné auparavant (Fraude !)
        }

        await _db.collection('tickets').doc(ticketId).update({'statut': 'SCANNE'});
        return true; // Validation réussie
      }
      return false; // Ticket introuvable
    } catch (e) {
      return false;
    }
  }
}