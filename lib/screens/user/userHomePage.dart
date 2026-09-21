import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ticketflow/screens/colors/appColors.dart';
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
                username: username, roleLabel: UserRole.label(UserRole.user)),
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
                MaterialPageRoute(builder: (_) => const CreateTicketPage()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Abrir novo chamado'),
            ),
          ),
            const SizedBox(height: 24),
            const SectionTitle('Meus Chamados'),
            StreamBuilder<List<TicketModel>>(
              stream: TicketService().streamCreatedBy(uid),
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
                if (tickets.isEmpty) {
                  return const EmptyState(
                      message: 'Você ainda não abriu nenhum chamado.');
                }
                return Column(
                  children: tickets.map((t) => TicketCard(ticket: t)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}