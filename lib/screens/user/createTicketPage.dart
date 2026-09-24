import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ticketflow/services/userService.dart';
import '../../models/ticketModel.dart';
import '../../services/ticketService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = TicketCategory.hardware;
  String _urgency = TicketUrgency.medium;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final me = await UserService().getUser(uid);
      final companyId = me?.companyId ?? uid;

      await TicketService().createTicket(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        companyId: companyId,
        category: _category,
        urgency: _urgency,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado aberto com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível abrir o chamado. Tente novamente.'),
        ),
      );
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    filled: true,
    fillColor: AppColors.inputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo chamado'),
        backgroundColor: AppColors.bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Categoria',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _decoration('Categoria'),
                  items: TicketCategory.all
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(c),
                            size: 18, color: AppColors.primaryColor),
                        const SizedBox(width: 8),
                        Text(TicketCategory.label(c)),
                      ],
                    ),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 20),
                const Text('Urgência',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TicketUrgency.all.map((u) {
                    final selected = u == _urgency;
                    final color = urgencyColor(u);
                    return ChoiceChip(
                      label: Text(TicketUrgency.label(u)),
                      selected: selected,
                      onSelected: (_) => setState(() => _urgency = u),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: color,
                      backgroundColor: color.withOpacity(0.1),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: _decoration('Título'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 6,
                  decoration: _decoration('Descreva o problema'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Descreva o problema'
                      : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Abrir chamado'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}