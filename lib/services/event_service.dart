import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupère les billets de l'utilisateur en cours
  Stream<QuerySnapshot> getUserTickets(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('billets')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  // Récupère tous les événements en direct
  Stream<QuerySnapshot> getEventsSnapshot() {
    return _db.collection('events').snapshots();
  }
}