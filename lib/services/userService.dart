import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/userModel.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('Users');

  Stream<List<AppUser>> streamUsers() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(AppUser.fromDoc).toList();
      list.sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return list;
    });
  }
}