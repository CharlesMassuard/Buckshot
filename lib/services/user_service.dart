import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupère le snapshot de l'utilisateur pour suivre son rôle en direct
  Stream<DocumentSnapshot> getUserSnapshot(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots();
  }
}