import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import '../user/ticketDetailPage.dart';
import 'openTicketsPage.dart';

class TechHomePage extends StatelessWidget {
  final String username;
  const TechHomePage({super.key, required this.username});

  /// Data em que o chamado foi assumido (último evento "em atendimento"
  /// no histórico); se não houver, cai para a data de criação.
  DateTime? _assumedAt(TicketModel t) {
    for (final event in t.history.reversed) {
      if (event.status == TicketStatus.inProgress) return event.at;
    }
    return t.createdAt;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: FutureBuilder<AppUser?>(
        future: UserService().getUser(uid),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final companyId = userSnap.data!.companyId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                    username: username, roleLabel: UserRole.label(UserRole.tech)),
                const SizedBox(height: 24),

                // Cards de métricas: total na fila, meus atendimentos
                // assumidos (em andamento) e total já resolvido por mim.
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<TicketModel>>(
                        stream: TicketService().streamOpen(companyId),
                        builder: (context, snap) {
                          final count = snap.data?.length ?? 0;
                          return StatCard(
                            title: 'Total na Fila',
                            value: '$count',
                            subtitle: 'Aguardando',
                            icon: Icons.pending_actions_outlined,
                            color: AppColors.secondaryColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<List<TicketModel>>(
                        stream: TicketService().streamAssignedTo(companyId, uid),
                        builder: (context, snap) {
                          final tickets = snap.data ?? [];
                          final inProgress =
                              tickets.where((t) => t.isInProgress).length;
                          return StatCard(
                            title: 'Meus Atendimentos',
                            value: '$inProgress',
                            subtitle: 'Assumidos',
                            icon: Icons.build_circle_outlined,
                            color: AppColors.primaryColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<List<TicketModel>>(
                        stream: TicketService().streamResolvedBy(companyId, uid),
                        builder: (context, snap) {
                          final count = snap.data?.length ?? 0;
                          return StatCard(
                            title: 'Resolvidos',
                            value: '$count',
                            subtitle: 'Total',
                            icon: Icons.check_circle_outline,
                            color: AppColors.successColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão para a fila geral, acima da lista de recentes.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Atendimentos Recentes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OpenTicketsPage()),
                      ),
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text('Fila geral'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<TicketModel>>(
                  stream: TicketService().streamAssignedTo(companyId, uid),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const EmptyState(
                          message: 'Erro ao carregar chamados.');
                    }
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final tickets = List<TicketModel>.from(snap.data!)
                      ..sort((a, b) => (_assumedAt(b) ?? DateTime(0))
                          .compareTo(_assumedAt(a) ?? DateTime(0)));
                    final recent = tickets.take(5).toList();

                    if (recent.isEmpty) {
                      return const EmptyState(
                          message: 'Você ainda não assumiu nenhum chamado.');
                    }
                    return Column(
                      children: recent
                          .map((t) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TicketDetailPage(ticketId: t.id),
                          ),
                        ),
                        child:
                        TicketCard(ticket: t, showAuthor: true),
                      ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}