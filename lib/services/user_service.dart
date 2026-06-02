import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  }
}