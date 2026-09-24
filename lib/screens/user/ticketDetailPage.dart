import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../services/ticketService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class TicketDetailPage extends StatelessWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shortTicketId(ticketId)),
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<TicketModel?>(
        stream: TicketService().streamTicket(ticketId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(message: 'Erro ao carregar o chamado.');
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ticket = snap.data;
          if (ticket == null) {
            return const EmptyState(message: 'Chamado não encontrado.');
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoChip(
                        icon: categoryIcon(ticket.category),
                        label: TicketCategory.label(ticket.category),
                      ),
                      InfoChip(
                        icon: Icons.priority_high_rounded,
                        label: 'Urgência: ${TicketUrgency.label(ticket.urgency)}',
                        color: urgencyColor(ticket.urgency),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descrição',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          ticket.description.isEmpty
                              ? 'Sem descrição.'
                              : ticket.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: 'Aberto por', value: ticket.createdByName),
                        _DetailRow(
                          label: 'Técnico responsável',
                          value: ticket.assignedToName ?? 'Aguardando técnico',
                        ),
                        _DetailRow(
                            label: 'Aberto em', value: formatDate(ticket.createdAt)),
                        if (ticket.resolvedAt != null)
                          _DetailRow(
                              label: 'Concluído em',
                              value: formatDate(ticket.resolvedAt)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SectionTitle('Histórico do chamado'),
                  if (ticket.history.isEmpty)
                    const EmptyState(message: 'Nenhum histórico registrado.')
                  else
                    ...List.generate(ticket.history.length, (i) {
                      final isLast = i == ticket.history.length - 1;
                      return _TimelineTile(
                        event: ticket.history[i],
                        isLast: isLast,
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.secondaryTextColor, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um "degrau" da timeline: bolinha colorida + linha vertical ligando ao
/// próximo evento, com o status, quem fez a mudança e quando.
class _TimelineTile extends StatelessWidget {
  final TicketHistoryEntry event;
  final bool isLast;
  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(event.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TicketStatus.label(event.status),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 13),
                  ),
                  if (event.byName != null) ...[
                    const SizedBox(height: 2),
                    Text('por ${event.byName}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.secondaryTextColor)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    formatDate(event.at),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}