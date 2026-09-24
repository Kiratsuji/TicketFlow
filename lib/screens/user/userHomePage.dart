import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ticketflow/screens/colors/appColors.dart';
import 'package:ticketflow/services/userService.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../widgets/appWidgets.dart';
import 'createTicketPage.dart';

class UserHomePage extends StatelessWidget {
  final String username;
  const UserHomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
        future: UserService().getUser(uid),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final companyId = userSnap.data!.companyId;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(
                      username: username,
                      roleLabel: UserRole.label(UserRole.user)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateTicketPage()),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Abrir novo chamado'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<TicketModel>>(
                    stream: TicketService().streamCreatedBy(companyId, uid),
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
                      final tickets = snap.data!;
                      final openCount =
                          tickets.where((t) => t.isOpen).length;
                      final inProgressCount =
                          tickets.where((t) => t.isInProgress).length;
                      final resolvedCount =
                          tickets.where((t) => t.isResolved).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('Meus Atendimentos'),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'Abertos',
                                  value: '$openCount',
                                  subtitle: 'Aguardando',
                                  icon: Icons.confirmation_number_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  title: 'Em atendimento',
                                  value: '$inProgressCount',
                                  subtitle: 'Com técnico',
                                  icon: Icons.build_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  title: 'Concluídos',
                                  value: '$resolvedCount',
                                  subtitle: 'Total',
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const SectionTitle('Meus Chamados'),
                          if (tickets.isEmpty)
                            const EmptyState(
                                message: 'Você ainda não abriu nenhum chamado.')
                          else
                            ...tickets
                                .map((t) => TicketSummaryRow(ticket: t)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}