import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserRole {
  static const String user = 'user';
  static const String tech = 'tech';
  static const String admin = 'admin';
  static const List<String> all = [user, tech, admin];

  static String label(String role) {
    switch (role) {
      case admin:
        return 'Administrador';
      case tech:
        return 'Técnico';
      default:
        return 'Usuário';
    }
  }
}

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String role;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      username: d['username'] ?? 'Sem nome',
      email: d['email'] ?? '',
      role: d['role'] ?? UserRole.user,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}