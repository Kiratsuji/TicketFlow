import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import '../tech/openTicketsPage.dart';
import 'usersPage.dart';

class AdminHomePage extends StatelessWidget {
  final String username;
  const AdminHomePage({super.key, required this.username});

  /// "3.5h" para médias abaixo de 1 dia, "2.1d" acima disso; "—" quando
  /// ainda não há nenhum chamado resolvido para calcular a média.
  String _averageResolutionLabel(List<TicketModel> tickets) {
    final resolved = tickets
        .where((t) => t.isResolved && t.createdAt != null && t.resolvedAt != null)
        .toList();
    if (resolved.isEmpty) return '—';

    final totalMinutes = resolved.fold<int>(
        0, (sum, t) => sum + t.resolvedAt!.difference(t.createdAt!).inMinutes);
    final avgHours = (totalMinutes / resolved.length) / 60;
    return avgHours < 24
        ? '${avgHours.toStringAsFixed(1)}h'
        : '${(avgHours / 24).toStringAsFixed(1)}d';
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

          return StreamBuilder<List<TicketModel>>(
            stream: TicketService().streamAll(companyId),
            builder: (context, snap) {
              final tickets = snap.data ?? [];
              final now = DateTime.now();

              final openedThisMonth = tickets
                  .where((t) =>
              t.createdAt != null &&
                  t.createdAt!.year == now.year &&
                  t.createdAt!.month == now.month)
                  .length;
              final waiting = tickets.where((t) => t.isOpen).length;
              final inProgress = tickets.where((t) => t.isInProgress).length;
              final recentOpen = tickets.where((t) => t.isOpen).take(3).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(
                        username: username,
                        roleLabel: UserRole.label(UserRole.admin)),
                    const SizedBox(height: 24),

                    // Indicadores da empresa.
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Abertos no Mês',
                            value: '$openedThisMonth',
                            subtitle: 'Este mês',
                            icon: Icons.calendar_month_outlined,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Tempo Médio',
                            value: _averageResolutionLabel(tickets),
                            subtitle: 'De resolução',
                            icon: Icons.timer_outlined,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Em Espera',
                            value: '$waiting',
                            subtitle: 'Aguardando técnico',
                            icon: Icons.hourglass_empty_rounded,
                            color: AppColors.primaryColorDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Em Atendimento',
                            value: '$inProgress',
                            subtitle: 'Com técnico',
                            icon: Icons.build_circle_outlined,
                            color: statusColor(TicketStatus.inProgress),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Gestão de usuários: resumo + atalho para a tela completa.
                    _SectionHeader(
                      title: 'Gestão de Usuários',
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UsersPage()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<AppUser>>(
                      stream: UserService().streamUsers(companyId),
                      builder: (context, userListSnap) {
                        if (!userListSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final users = userListSnap.data!.take(4).toList();
                        if (users.isEmpty) {
                          return const EmptyState(
                              message: 'Nenhum usuário cadastrado.');
                        }
                        return Column(
                          children:
                          users.map((u) => UserTile(user: u)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Chamados recentes: só os abertos, com atalho para a fila.
                    _SectionHeader(
                      title: 'Chamados Recentes',
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OpenTicketsPage()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recentOpen.isEmpty)
                      const EmptyState(message: 'Nenhum chamado aberto no momento.')
                    else
                      ...recentOpen
                          .map((t) => TicketCard(ticket: t, showAuthor: true)),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Ver Todos'),
        ),
      ],
    );
  }
}