import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../widgets/appWidgets.dart';

class TechHomePage extends StatelessWidget {
  final String username;
  const TechHomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
                username: username, roleLabel: UserRole.label(UserRole.tech)),
            const SizedBox(height: 24),
            StreamBuilder<List<TicketModel>>(
              stream: TicketService().streamResolvedBy(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(message: 'Erro ao carregar chamados.');
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final tickets = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatCard(
                      title: 'Resolvidos por mim',
                      value: '${tickets.length}',
                      subtitle: 'Total',
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Chamados que resolvi'),
                    if (tickets.isEmpty)
                      const EmptyState(
                          message: 'Você ainda não resolveu nenhum chamado.')
                    else
                      ...tickets.map((t) => TicketCard(ticket: t, showAuthor: true)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}