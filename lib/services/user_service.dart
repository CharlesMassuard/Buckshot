import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

<<<<<<< HEAD
  // Récupère le snapshot de l'utilisateur pour suivre son rôle en direct
  Stream<DocumentSnapshot> getUserSnapshot(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots();
=======
  // Stream du rôle de l'utilisateur
  Stream<String> getUserRole(String? uid) {
    if (uid == null) return Stream.value('USER');
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data();
        return userData?['role'] ?? 'USER';
      }
      return 'USER';
    });
>>>>>>> ff7368ba854f8c469e94bd9a296fba73aa96a4e5
  }
}