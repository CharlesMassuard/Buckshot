import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

<<<<<<< HEAD
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
=======
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
>>>>>>> ff7368ba854f8c469e94bd9a296fba73aa96a4e5
  }
}