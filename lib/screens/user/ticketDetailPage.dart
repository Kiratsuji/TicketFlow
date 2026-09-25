import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import 'closeTicketPage.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late final Future<AppUser?> _viewerFuture =
  UserService().getUser(FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(shortTicketId(widget.ticketId)),
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<AppUser?>(
        future: _viewerFuture,
        builder: (context, viewerSnap) {
          final viewerRole = viewerSnap.data?.role;
          // Só técnico e admin podem registrar a solução de um chamado.
          final canManage =
              viewerRole == UserRole.tech || viewerRole == UserRole.admin;

          return StreamBuilder<TicketModel?>(
            stream: TicketService().streamTicket(widget.ticketId),
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

              final showCloseButton = canManage && !ticket.isResolved;

              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
                                  label:
                                  'Urgência: ${TicketUrgency.label(ticket.urgency)}',
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
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
                            if (ticket.isResolved && ticket.solution != null)
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.task_alt_rounded,
                                            size: 16,
                                            color: AppColors.successColor),
                                        const SizedBox(width: 6),
                                        const Text('Solução registrada',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ticket.solution!.isEmpty
                                          ? 'Sem descrição da solução.'
                                          : ticket.solution!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (ticket.closureReason != null) ...[
                                      const SizedBox(height: 10),
                                      InfoChip(
                                        icon: Icons.label_outline_rounded,
                                        label: TicketClosureReason.label(
                                            ticket.closureReason!),
                                        color: AppColors.successColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailRow(
                                      label: 'Aberto por',
                                      value: ticket.createdByName),
                                  _DetailRow(
                                    label: 'Técnico responsável',
                                    value: ticket.assignedToName ??
                                        'Aguardando técnico',
                                  ),
                                  _DetailRow(
                                      label: 'Aberto em',
                                      value: formatDate(ticket.createdAt)),
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
                              const EmptyState(
                                  message: 'Nenhum histórico registrado.')
                            else
                              ...List.generate(ticket.history.length, (i) {
                                final isLast =
                                    i == ticket.history.length - 1;
                                return _TimelineTile(
                                  event: ticket.history[i],
                                  isLast: isLast,
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    // Botão fixo no rodapé, só para técnico/admin e apenas
                    // enquanto o chamado ainda não foi concluído.
                    if (showCloseButton)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.bgColor,
                          border: Border(
                            top: BorderSide(color: AppColors.borderColor),
                          ),
                        ),
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CloseTicketPage(ticket: ticket),
                              ),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_outlined),
                            label: const Text('Registrar Solução'),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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