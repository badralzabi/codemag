import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<UserCredential> registerWithEmailAndPassword(
    String email, 
    String password, 
    String username, 
    String displayName
  ) async {
    // Check if username already exists BEFORE creating auth user
    DocumentSnapshot usernameDoc = await _firestore.collection('usernames').doc(username).get();
    if (usernameDoc.exists) {
      throw Exception('اسم المستخدم مسجل مسبقاً، يرجى اختيار اسم آخر.');
    }

    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;
    
    if (user != null) {
      String avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random';
      
      UserModel newUser = UserModel(
        uid: user.uid,
        email: email,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      WriteBatch batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), newUser.toMap());
      batch.set(_firestore.collection('usernames').doc(username), {'uid': user.uid});
      
      await batch.commit();
    }
    
    return result;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
