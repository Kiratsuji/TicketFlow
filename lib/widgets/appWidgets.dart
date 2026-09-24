import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/ticketModel.dart';
import '../screens/colors/appColors.dart';

String formatDate(DateTime? d) {
  if (d == null) return '...';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String shortTicketId(String id) =>
    '#${(id.length > 6 ? id.substring(0, 6) : id).toUpperCase()}';

// Cor de cada status, centralizada aqui para todos os widgets usarem a
// mesma paleta.
Color statusColor(String status) {
  switch (status) {
    case TicketStatus.resolved:
      return AppColors.successColor;
    case TicketStatus.inProgress:
      return Colors.orange;
    default:
      return AppColors.primaryColor;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case TicketCategory.hardware:
      return Icons.computer_outlined;
    case TicketCategory.software:
      return Icons.apps_outlined;
    case TicketCategory.network:
      return Icons.wifi_outlined;
    case TicketCategory.access:
      return Icons.lock_outline;
    default:
      return Icons.help_outline;
  }
}

Color urgencyColor(String urgency) {
  switch (urgency) {
    case TicketUrgency.low:
      return AppColors.successColor;
    case TicketUrgency.high:
      return Colors.orange;
    case TicketUrgency.critical:
      return AppColors.errorColor;
    default:
      return Colors.amber.shade700;
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const AppCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: child,
    );
  }
}

class DashboardHeader extends StatelessWidget {
  final String username;
  final String roleLabel;
  const DashboardHeader({super.key, required this.username, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.borderColor)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.errorColor),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  );
}

class StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.secondaryTextColor, fontSize: 10)),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(TicketStatus.label(status),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

/// Chip pequeno com ícone + texto, usado para mostrar categoria/urgência
/// na página de detalhes do chamado.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const InfoChip({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool showAuthor;
  final Widget? action;
  const TicketCard({
    super.key,
    required this.ticket,
    this.showAuthor = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final meta = showAuthor
        ? '${ticket.createdByName} • ${formatDate(ticket.createdAt)}'
        : formatDate(ticket.createdAt);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ticket.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: ticket.status),
            ],
          ),
          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(meta,
              style: const TextStyle(
                  color: AppColors.secondaryTextColor, fontSize: 11)),
          if (action != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      ),
    );
  }
}

/// Card em formato de "linha de tabela": id, título, técnico responsável,
/// data de abertura e status — usado na lista de chamados da dashboard
/// do usuário padrão. Clicável quando [onTap] é informado.
class TicketSummaryRow extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;
  const TicketSummaryRow({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortTicketId(ticket.id),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryTextColor),
                ),
                StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.build_outlined,
                    size: 14, color: AppColors.secondaryTextColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ticket.assignedToName ?? 'Aguardando técnico',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.secondaryTextColor),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  formatDate(ticket.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.disabledColor),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryTextColor)),
          ],
        ),
      ),
    );
  }
}