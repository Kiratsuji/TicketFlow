import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/userModel.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('Users');

  /// Lista só os usuários da mesma empresa (mesmo companyId).
  Stream<List<AppUser>> streamUsers(String companyId) {
    return _col
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AppUser.fromDoc).toList();
      list.sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return list;
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// Atualiza o nome exibido do usuário no Firestore (o displayName do
  /// FirebaseAuth é atualizado à parte, na própria tela de perfil).
  Future<void> updateUsername(String uid, String username) {
    return _col.doc(uid).update({'username': username});
  }
}