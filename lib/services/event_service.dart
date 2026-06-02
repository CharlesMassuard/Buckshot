import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream des billets de l'utilisateur connecté
  Stream<Set<String>> getMyRegisteredEventIds(String? uid) {
    if (uid == null) return Stream.value({});
    return _db
        .collection('billets')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data())['eventId'] as String? ?? '')
            .toSet());
  }

  // Stream de tous les événements
  Stream<List<QueryDocumentSnapshot>> getAllEvents() {
    return _db.collection('events').snapshots().map((snapshot) => snapshot.docs);
  }

  // Stream pour savoir si l'utilisateur a des favoris / rappels
  Stream<bool> hasFavorites(String? uid) {
    if (uid == null) return Stream.value(false);
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}