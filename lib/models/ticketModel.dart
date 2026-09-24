import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TicketStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';

  static String label(String status) {
    switch (status) {
      case resolved:
        return 'Concluído';
      case inProgress:
        return 'Em atendimento';
      default:
        return 'Aberto';
    }
  }
}

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
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
    this.assignedTo,
    this.assignedToName,
    this.resolvedBy,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
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
      assignedTo: d['assignedTo'],
      assignedToName: d['assignedToName'],
      resolvedBy: d['resolvedBy'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}