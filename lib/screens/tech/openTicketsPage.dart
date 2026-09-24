import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class OpenTicketsPage extends StatelessWidget {
  const OpenTicketsPage({super.key});

  Future<void> _resolve(BuildContext context, TicketModel ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver chamado'),
        content: Text('Marcar "${ticket.title}" como resolvido?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resolver')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await TicketService().resolveTicket(ticket.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível resolver o chamado.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Chamados abertos'),
            Expanded(
              child: FutureBuilder<AppUser?>(
                future: UserService().getUser(uid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final companyId = userSnap.data!.companyId;

                  return StreamBuilder<List<TicketModel>>(
                    stream: TicketService().streamOpen(companyId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const EmptyState(
                            message: 'Erro ao carregar chamados.');
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final tickets = snap.data!;
                      if (tickets.isEmpty) {
                        return const EmptyState(
                            message: 'Nenhum chamado aberto. Bom trabalho!',
                            icon: Icons.celebration_outlined);
                      }
                      return ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (_, i) => TicketCard(
                          ticket: tickets[i],
                          showAuthor: true,
                          action: FilledButton.tonalIcon(
                            onPressed: () => _resolve(context, tickets[i]),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Resolver'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}