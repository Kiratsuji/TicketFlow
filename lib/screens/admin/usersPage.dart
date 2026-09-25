import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../models/userModel.dart';
import '../../services/ticketService.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import 'createUserPage.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late final Future<AppUser?> _viewerFuture = UserService().getUser(_uid);

  final _searchController = TextEditingController();
  String _search = '';
  String? _roleFilter; // null = todos

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _applyFilters(List<AppUser> users) {
    var list = users;
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((u) => u.username.toLowerCase().contains(query)).toList();
    }
    if (_roleFilter != null) {
      list = list.where((u) => u.role == _roleFilter).toList();
    }
    return list;
  }

  Future<void> _confirmDelete(BuildContext context, AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text(
          'Remover o acesso de "${user.username}" a este sistema?\n\n'
              'Isso apaga o cadastro dele no app, mas não exclui a conta de '
              'login por completo — isso exige um passo manual adicional, '
              'fora do app.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style:
            FilledButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await UserService().deleteUser(user.uid);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível excluir o usuário.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _viewerFuture,
      builder: (context, viewerSnap) {
        if (!viewerSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final companyId = viewerSnap.data!.companyId;

        // Material transparente: só existe para dar o ancestor que
        // TextField/DropdownButtonFormField exigem. Não pinta nada, então
        // funciona igual tanto quando esta tela é aberta como aba (dentro
        // do Scaffold da navbar) quanto quando é empurrada como rota cheia
        // (ex.: pelo botão "Ver Todos" da dashboard do admin).
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Usuários',
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateUserPage()),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Novo usuário'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Busca por nome.
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtro por nível de acesso.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _roleFilter == null,
                        onSelected: (_) => setState(() => _roleFilter = null),
                      ),
                      ...UserRole.all.map((r) => ChoiceChip(
                        label: Text(UserRole.label(r)),
                        selected: _roleFilter == r,
                        onSelected: (_) => setState(() => _roleFilter = r),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<List<AppUser>>(
                    stream: UserService().streamUsers(companyId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const EmptyState(
                            message: 'Erro ao carregar usuários.');
                      }
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final allUsers = snap.data!;
                      final filtered = _applyFilters(allUsers);
                      final techUsers =
                      allUsers.where((u) => u.role == UserRole.tech).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (filtered.isEmpty)
                            const EmptyState(
                                message: 'Nenhum usuário encontrado.')
                          else
                            ...filtered.map((u) => UserTile(
                              user: u,
                              isSelf: u.uid == _uid,
                              onDelete: () => _confirmDelete(context, u),
                            )),
                          const SizedBox(height: 28),
                          _ReassignSection(
                            companyId: companyId,
                            techUsers: techUsers,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class UserTile extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback? onDelete;
  const UserTile({
    super.key,
    required this.user,
    this.isSelf = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inputFillColor,
            child: Icon(Icons.person, size: 18, color: AppColors.secondaryTextColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.secondaryTextColor, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(UserRole.label(user.role),
                style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          if (onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.secondaryTextColor),
              onSelected: (v) {
                if (v == 'delete') onDelete!();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  enabled: !isSelf,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18,
                          color: isSelf
                              ? AppColors.disabledColor
                              : AppColors.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        isSelf ? 'Você não pode se excluir' : 'Excluir usuário',
                        style: TextStyle(
                            color: isSelf
                                ? AppColors.disabledColor
                                : AppColors.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Seção fixa no final da tela de usuários: escolhe um chamado em
/// atendimento e um novo técnico responsável para reatribuí-lo.
class _ReassignSection extends StatefulWidget {
  final String companyId;
  final List<AppUser> techUsers;
  const _ReassignSection({required this.companyId, required this.techUsers});

  @override
  State<_ReassignSection> createState() => _ReassignSectionState();
}

class _ReassignSectionState extends State<_ReassignSection> {
  String? _ticketId;
  String? _techUid;
  bool _isSaving = false;

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.inputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _reassign(String ticketId, AppUser tech) async {
    setState(() => _isSaving = true);
    try {
      await TicketService().reassignTicket(
        ticketId: ticketId,
        newTechUid: tech.uid,
        newTechName: tech.username,
      );
      if (!mounted) return;
      setState(() {
        _ticketId = null;
        _techUid = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado reatribuído com sucesso!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível reatribuir o chamado.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Reatribuição de Chamados'),
        if (widget.techUsers.isEmpty)
          const EmptyState(
              message: 'Cadastre um técnico para poder reatribuir chamados.')
        else
          AppCard(
            child: StreamBuilder<List<TicketModel>>(
              stream: TicketService().streamInProgress(widget.companyId),
              builder: (context, snap) {
                final tickets = snap.data ?? [];
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (tickets.isEmpty) {
                  return const Text(
                    'Nenhum chamado em atendimento no momento.',
                    style: TextStyle(
                        color: AppColors.secondaryTextColor, fontSize: 13),
                  );
                }

                // Se o chamado selecionado saiu da lista (ex.: foi
                // concluído por outra pessoa), a seleção simplesmente some
                // do dropdown em vez de quebrar o widget.
                final currentTicketId =
                tickets.any((t) => t.id == _ticketId) ? _ticketId : null;
                final currentTechUid = widget.techUsers
                    .any((t) => t.uid == _techUid)
                    ? _techUid
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: currentTicketId,
                      decoration: _decoration('Chamado'),
                      isExpanded: true,
                      items: tickets
                          .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          '${shortTicketId(t.id)} • ${t.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _ticketId = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: currentTechUid,
                      decoration: _decoration('Novo técnico responsável'),
                      isExpanded: true,
                      items: widget.techUsers
                          .map((t) => DropdownMenuItem(
                        value: t.uid,
                        child: Text(t.username),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _techUid = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: (currentTicketId == null ||
                            currentTechUid == null ||
                            _isSaving)
                            ? null
                            : () => _reassign(
                          currentTicketId,
                          widget.techUsers
                              .firstWhere((t) => t.uid == currentTechUid),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Reatribuir'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}