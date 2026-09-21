import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TicketStatus {
  static const String open = 'open';
  static const String resolved = 'resolved';

  static String label(String status) =>
      status == resolved ? 'Resolvido' : 'Aberto';
}

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String createdBy;
  final String createdByName;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    this.resolvedBy,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isResolved => status == TicketStatus.resolved;

  factory TicketModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TicketModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      status: d['status'] ?? TicketStatus.open,
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? 'Usuário',
      resolvedBy: d['resolvedBy'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}