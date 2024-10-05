import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      return userDoc['username'] as String?;
    }
    return 'Guest';
  }

  Future<List<dynamic>> getMenu() async {
    QuerySnapshot menuSnapshot = await _db.collection('menu').get();
    return menuSnapshot.docs.map((doc) => doc.data()).toList();
  }
  Future<void> updateUserSetupStatus(String userId, bool isSetupComplete) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isSetupComplete': isSetupComplete,
    });
    print('Document successfully updated!');
  } catch (e) {
    print('Error updating document: $e');
  }
}
}
