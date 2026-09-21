import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ticketModel.dart';

class TicketService {
  final _col = FirebaseFirestore.instance.collection('Tickets');

  Stream<List<TicketModel>> _stream(Query<Map<String, dynamic>> query) {
    return query.snapshots().map((snap) {
      final list = snap.docs.map(TicketModel.fromDoc).toList();
      final now = DateTime.now();
      list.sort((a, b) =>
          (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return list;
    });
  }

  Stream<List<TicketModel>> streamAll() => _stream(_col);

  Stream<List<TicketModel>> streamCreatedBy(String uid) =>
      _stream(_col.where('createdBy', isEqualTo: uid));

  Stream<List<TicketModel>> streamResolvedBy(String uid) =>
      _stream(_col.where('resolvedBy', isEqualTo: uid));

  Stream<List<TicketModel>> streamOpen() =>
      _stream(_col.where('status', isEqualTo: TicketStatus.open));

  Future<void> createTicket({
    required String title,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _col.add({
      'title': title,
      'description': description,
      'status': TicketStatus.open,
      'createdBy': user.uid,
      'createdByName': user.displayName ?? 'Usuário',
      'resolvedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  Future<void> resolveTicket(String ticketId) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _col.doc(ticketId).update({
      'status': TicketStatus.resolved,
      'resolvedBy': user.uid,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}