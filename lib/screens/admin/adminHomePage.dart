import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';

class AdminHomePage extends StatelessWidget {
  final String username;
  const AdminHomePage({super.key, required this.username});

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
              final open = tickets.where((t) => !t.isResolved).length;
              final resolved = tickets.length - open;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(
                        username: username,
                        roleLabel: UserRole.label(UserRole.admin)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Chamados abertos',
                            value: '$open',
                            subtitle: 'Aguardando',
                            icon: Icons.confirmation_number_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Resolvidos',
                            value: '$resolved',
                            subtitle: 'Total',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Chamados Recentes'),
                    if (tickets.isEmpty)
                      const EmptyState(message: 'Nenhum chamado ainda.')
                    else
                      ...tickets
                          .take(5)
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