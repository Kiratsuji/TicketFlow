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

abstract class TicketCategory {
  static const String hardware = 'hardware';
  static const String software = 'software';
  static const String network = 'network';
  static const String access = 'access';
  static const String other = 'other';
  static const List<String> all = [hardware, software, network, access, other];

  static String label(String category) {
    switch (category) {
      case hardware:
        return 'Hardware';
      case software:
        return 'Software';
      case network:
        return 'Rede';
      case access:
        return 'Acesso';
      default:
        return 'Outro';
    }
  }
}

abstract class TicketUrgency {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
  static const List<String> all = [low, medium, high, critical];

  static String label(String urgency) {
    switch (urgency) {
      case low:
        return 'Baixa';
      case high:
        return 'Alta';
      case critical:
        return 'Crítica';
      default:
        return 'Média';
    }
  }
}

/// Dropdown auxiliar da tela de fechamento: classifica o motivo/tipo do
/// encerramento, além da descrição livre da solução.
abstract class TicketClosureReason {
  static const String resolved = 'resolved';
  static const String notReproduced = 'not_reproduced';
  static const String duplicate = 'duplicate';
  static const String cancelled = 'cancelled';
  static const String other = 'other';
  static const List<String> all = [
    resolved,
    notReproduced,
    duplicate,
    cancelled,
    other,
  ];

  static String label(String reason) {
    switch (reason) {
      case notReproduced:
        return 'Não foi possível reproduzir';
      case duplicate:
        return 'Duplicado';
      case cancelled:
        return 'Cancelado pelo solicitante';
      case other:
        return 'Outro';
      default:
        return 'Resolvido';
    }
  }
}

/// Um registro de mudança no chamado (abertura, técnico assumiu, resolução...)
/// usado para montar a timeline na página de detalhes.
class TicketHistoryEntry {
  final String status;
  final String? byName;
  final DateTime? at;

  const TicketHistoryEntry({required this.status, this.byName, this.at});

  factory TicketHistoryEntry.fromMap(Map<String, dynamic> m) {
    return TicketHistoryEntry(
      status: m['status'] ?? '',
      byName: m['byName'],
      at: (m['at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'status': status,
    'byName': byName,
    'at': Timestamp.fromDate(at ?? DateTime.now()),
  };
}

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String category;
  final String urgency;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final String? resolvedBy;
  final String? solution;
  final String? closureReason;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final List<TicketHistoryEntry> history;

  const TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.urgency,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    this.resolvedBy,
    this.solution,
    this.closureReason,
    this.createdAt,
    this.resolvedAt,
    this.history = const [],
  });

  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;

  factory TicketModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawHistory = (d['history'] as List?) ?? [];
    return TicketModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      status: d['status'] ?? TicketStatus.open,
      category: d['category'] ?? TicketCategory.other,
      urgency: d['urgency'] ?? TicketUrgency.medium,
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? 'Usuário',
      assignedTo: d['assignedTo'],
      assignedToName: d['assignedToName'],
      resolvedBy: d['resolvedBy'],
      solution: d['solution'],
      closureReason: d['closureReason'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
      history: rawHistory
          .map((e) => TicketHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}