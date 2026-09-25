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

  Stream<List<TicketModel>> streamAssignedTo(String companyId, String uid) =>
      _stream(_col
          .where('companyId', isEqualTo: companyId)
          .where('assignedTo', isEqualTo: uid));

  Stream<TicketModel?> streamTicket(String ticketId) {
    return _col.doc(ticketId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TicketModel.fromDoc(doc);
    });
  }

  Stream<List<TicketModel>> streamInProgress(String companyId) => _stream(_col
      .where('companyId', isEqualTo: companyId)
      .where('status', isEqualTo: TicketStatus.inProgress));

  Future<void> createTicket({
    required String title,
    required String description,
    required String companyId,
    required String category,
    required String urgency,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final createdByName = user.displayName ?? 'Usuário';
    await _col.add({
      'title': title,
      'description': description,
      'status': TicketStatus.open,
      'category': category,
      'urgency': urgency,
      'companyId': companyId,
      'createdBy': user.uid,
      'createdByName': createdByName,
      'assignedTo': null,
      'assignedToName': null,
      'resolvedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'history': [
        TicketHistoryEntry(
          status: TicketStatus.open,
          byName: createdByName,
          at: DateTime.now(),
        ).toMap(),
      ],
    });
  }

  Future<void> takeTicket(String ticketId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final byName = user.displayName ?? 'Técnico';
    await _col.doc(ticketId).update({
      'status': TicketStatus.inProgress,
      'assignedTo': user.uid,
      'assignedToName': byName,
      'history': FieldValue.arrayUnion([
        TicketHistoryEntry(
          status: TicketStatus.inProgress,
          byName: byName,
          at: DateTime.now(),
        ).toMap(),
      ]),
    });
  }

  Future<void> resolveTicket(
      String ticketId, {
        required String solution,
        required String closureReason,
      }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final byName = user.displayName ?? 'Técnico';
    await _col.doc(ticketId).update({
      'status': TicketStatus.resolved,
      'assignedTo': user.uid,
      'assignedToName': byName,
      'resolvedBy': user.uid,
      'resolvedAt': FieldValue.serverTimestamp(),
      'solution': solution,
      'closureReason': closureReason,
      'history': FieldValue.arrayUnion([
        TicketHistoryEntry(
          status: TicketStatus.resolved,
          byName: byName,
          at: DateTime.now(),
        ).toMap(),
      ]),
    });
  }

  Future<void> reassignTicket({
    required String ticketId,
    required String newTechUid,
    required String newTechName,
  }) async {
    final admin = FirebaseAuth.instance.currentUser!;
    final doc = await _col.doc(ticketId).get();
    final data = doc.data();
    final oldTechName = data?['assignedToName'] as String?;
    final currentStatus =
        (data?['status'] as String?) ?? TicketStatus.inProgress;

    await _col.doc(ticketId).update({
      'assignedTo': newTechUid,
      'assignedToName': newTechName,
      'history': FieldValue.arrayUnion([
        TicketHistoryEntry(
          status: currentStatus,
          byName: admin.displayName ?? 'Admin',
          note: oldTechName != null
              ? 'Reatribuído de $oldTechName para $newTechName'
              : 'Atribuído para $newTechName',
          at: DateTime.now(),
        ).toMap(),
      ]),
    });
  }
}