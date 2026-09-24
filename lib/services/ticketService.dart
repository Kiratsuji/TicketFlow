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

  Stream<List<TicketModel>> streamAll(String companyId) =>
      _stream(_col.where('companyId', isEqualTo: companyId));

  Stream<List<TicketModel>> streamCreatedBy(String companyId, String uid) =>
      _stream(_col
          .where('companyId', isEqualTo: companyId)
          .where('createdBy', isEqualTo: uid));

  Stream<List<TicketModel>> streamResolvedBy(String companyId, String uid) =>
      _stream(_col
          .where('companyId', isEqualTo: companyId)
          .where('resolvedBy', isEqualTo: uid));

  Stream<List<TicketModel>> streamOpen(String companyId) => _stream(_col
      .where('companyId', isEqualTo: companyId)
      .where('status', isEqualTo: TicketStatus.open));

  Future<void> createTicket({
    required String title,
    required String description,
    required String companyId,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _col.add({
      'title': title,
      'description': description,
      'status': TicketStatus.open,
      'companyId': companyId,
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