import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import '../user/ticketDetailPage.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<AppUser?>(
        future: UserService().getUser(uid),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<TicketModel>>(
            stream: TicketService().streamAll(userSnap.data!.companyId),
            builder: (context, ticketSnap) {
              if (ticketSnap.hasError) {
                return const EmptyState(
                  message: 'Erro ao carregar o relatório.',
                );
              }
              if (!ticketSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tickets = ticketSnap.data!;
              final open = tickets
                  .where((t) => t.status == TicketStatus.open)
                  .length;
              final inProgress = tickets
                  .where((t) => t.status == TicketStatus.inProgress)
                  .length;
              final resolved = tickets
                  .where((t) => t.status == TicketStatus.resolved)
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visão geral',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ReportMetric(
                          label: 'Total',
                          value: tickets.length,
                          color: AppColors.primaryColor,
                        ),
                        _ReportMetric(
                          label: 'Abertos',
                          value: open,
                          color: AppColors.primaryColorDark,
                        ),
                        _ReportMetric(
                          label: 'Em atendimento',
                          value: inProgress,
                          color: Colors.orange,
                        ),
                        _ReportMetric(
                          label: 'Concluídos',
                          value: resolved,
                          color: AppColors.successColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SectionTitle('Chamados por categoria'),
                    AppCard(
                      child: Column(
                        children: TicketCategory.all.map((category) {
                          final count = tickets
                              .where((t) => t.category == category)
                              .length;
                          return _ReportRow(
                            label: TicketCategory.label(category),
                            value: '$count',
                            icon: categoryIcon(category),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionTitle('Todos os chamados'),
                    if (tickets.isEmpty)
                      const EmptyState(message: 'Nenhum chamado encontrado.')
                    else
                      ...tickets.map(
                        (ticket) => TicketCard(
                          ticket: ticket,
                          showAuthor: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TicketDetailPage(ticketId: ticket.id),
                            ),
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

class _ReportMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.analytics_outlined, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReportRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
