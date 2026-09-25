import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

enum _QueueTab { fila, meus }

class OpenTicketsPage extends StatefulWidget {
  const OpenTicketsPage({super.key});

  @override
  State<OpenTicketsPage> createState() => _OpenTicketsPageState();
}

class _OpenTicketsPageState extends State<OpenTicketsPage> {
  late final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late final Future<AppUser?> _userFuture = UserService().getUser(_uid);

  _QueueTab _tab = _QueueTab.fila;

  final _searchController = TextEditingController();
  String _search = '';
  String? _categoryFilter;
  String? _urgencyFilter;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _take(BuildContext context, TicketModel ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assumir chamado'),
        content: Text('Assumir "${ticket.title}" para você?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Assumir')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await TicketService().takeTicket(ticket.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível assumir o chamado.'),
        ),
      );
    }
  }

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

  List<TicketModel> _applyFilters(List<TicketModel> tickets) {
    var list = tickets;
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((t) =>
      t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query))
          .toList();
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.category == _categoryFilter).toList();
    }
    if (_urgencyFilter != null) {
      list = list.where((t) => t.urgency == _urgencyFilter).toList();
    }
    return list;
  }

  InputDecoration _filterDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.inputFillColor,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  bool get _hasActiveFilters =>
      _categoryFilter != null || _urgencyFilter != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
            _tab == _QueueTab.fila ? 'Fila de Chamados' : 'Meus Atendimentos'),
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alternância entre a fila geral e os chamados que o técnico
              // já assumiu.
              SegmentedButton<_QueueTab>(
                segments: const [
                  ButtonSegment(
                    value: _QueueTab.fila,
                    label: Text('Fila'),
                    icon: Icon(Icons.inbox_outlined),
                  ),
                  ButtonSegment(
                    value: _QueueTab.meus,
                    label: Text('Meus Atendimentos'),
                    icon: Icon(Icons.build_outlined),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primaryColor,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Busca por texto + botão para revelar os filtros avançados.
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por título ou descrição...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showFilters || _hasActiveFilters
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                      color: _showFilters || _hasActiveFilters
                          ? AppColors.primaryColor
                          : null,
                    ),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_showFilters) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _categoryFilter,
                        decoration: _filterDecoration('Categoria'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todas')),
                          ...TicketCategory.all.map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryIcon(c),
                                    size: 16,
                                    color: AppColors.primaryColor),
                                const SizedBox(width: 6),
                                Text(TicketCategory.label(c)),
                              ],
                            ),
                          )),
                        ],
                        onChanged: (v) => setState(() => _categoryFilter = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _urgencyFilter,
                        decoration: _filterDecoration('Prioridade'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todas')),
                          ...TicketUrgency.all.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              TicketUrgency.label(u),
                              style: TextStyle(
                                  color: urgencyColor(u),
                                  fontWeight: FontWeight.w600),
                            ),
                          )),
                        ],
                        onChanged: (v) => setState(() => _urgencyFilter = v),
                      ),
                    ),
                  ],
                ),
                if (_hasActiveFilters)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _categoryFilter = null;
                        _urgencyFilter = null;
                      }),
                      child: const Text('Limpar filtros'),
                    ),
                  ),
              ],
              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<AppUser?>(
                  future: _userFuture,
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final companyId = userSnap.data!.companyId;
                    final stream = _tab == _QueueTab.fila
                        ? TicketService().streamOpen(companyId)
                        : TicketService().streamAssignedTo(companyId, _uid);

                    return StreamBuilder<List<TicketModel>>(
                      stream: stream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const EmptyState(
                              message: 'Erro ao carregar chamados.');
                        }
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var tickets = snap.data!;
                        if (_tab == _QueueTab.meus) {
                          tickets =
                              tickets.where((t) => t.isInProgress).toList();
                        }
                        tickets = _applyFilters(tickets);

                        if (tickets.isEmpty) {
                          return EmptyState(
                            message: _tab == _QueueTab.fila
                                ? 'Nenhum chamado na fila. Bom trabalho!'
                                : 'Você não tem atendimentos em andamento.',
                            icon: _tab == _QueueTab.fila
                                ? Icons.celebration_outlined
                                : Icons.inbox_outlined,
                          );
                        }

                        return ListView.builder(
                          itemCount: tickets.length,
                          itemBuilder: (_, i) {
                            final ticket = tickets[i];
                            return TicketCard(
                              ticket: ticket,
                              showAuthor: true,
                              action: _tab == _QueueTab.fila
                                  ? FilledButton.tonalIcon(
                                onPressed: () => _take(context, ticket),
                                icon: const Icon(
                                    Icons.assignment_ind_outlined,
                                    size: 18),
                                label: const Text('Assumir'),
                              )
                                  : FilledButton.tonalIcon(
                                onPressed: () =>
                                    _resolve(context, ticket),
                                icon: const Icon(Icons.check_rounded,
                                    size: 18),
                                label: const Text('Resolver'),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}