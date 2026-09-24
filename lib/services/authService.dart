import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/userModel.dart';

class AuthService {
  static const String defaultPassword = 'Ticket@123';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Busca o documento Firestore do usuário logado (contém role e companyId).
  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('Users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// Cadastro público. Cada conta criada aqui é a fundadora de uma nova
  /// empresa isolada: vira admin, mas só enxerga dados com companyId ==
  /// o próprio uid. Não existe mais "admin global".
  Future<User?> userSignUp(String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await user.updateDisplayName(username);
        await user.reload();
        await _db.collection('Users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'role': UserRole.admin,
          'companyId': user.uid, // esta conta é a dona da própria empresa
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } on FirebaseException catch (e) {
      await _auth.currentUser?.delete();
      throw Exception('Não foi possível salvar seus dados: ${e.message}');
    }
  }

  Future<User?> userLogin(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Cadastro feito por um admin. O novo usuário herda o companyId do
  /// admin que está cadastrando — ou seja, entra na mesma empresa dele,
  /// nunca cria uma empresa nova.
  Future<void> createUserByAdmin({
    required String username,
    required String email,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final adminUid = _auth.currentUser!.uid;
      final adminDoc = await _db.collection('Users').doc(adminUid).get();
      final companyId = adminDoc.data()?['companyId'] ?? adminUid;

      secondaryApp = await Firebase.initializeApp(
        name: 'secondary-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: defaultPassword,
      );
      final newUser = cred.user!;

      try {
        await newUser.updateDisplayName(username);
        await _db.collection('Users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'username': username,
          'email': email,
          'role': role,
          'companyId': companyId,
          'mustChangePassword': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        await newUser.delete();
        throw Exception('Não foi possível salvar os dados: ${e.message}');
      }

      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } finally {
      await secondaryApp?.delete();
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      default:
        return e.message ?? 'Ocorreu um erro. Tente novamente.';
    }
  }
}