import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> userSignUp(String email, String password, String username) async{
    try{
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final user = result.user;

      if(user!=null){
        user.updateDisplayName(username);
        await user.reload();

        await _db.collection('Users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e){
      throw Exception(e.message);
    }
  }
  Future<User?> userLogin(String email, String password) async{
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);

      return result.user;
    }on FirebaseAuthException catch(e){
      throw Exception(e.message);
    }
  }
}