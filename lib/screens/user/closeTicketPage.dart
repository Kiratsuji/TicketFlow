import 'package:flutter/material.dart';
import '../../models/ticketModel.dart';
import '../../services/ticketService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class CloseTicketPage extends StatefulWidget {
  final TicketModel ticket;
  const CloseTicketPage({super.key, required this.ticket});

  @override
  State<CloseTicketPage> createState() => _CloseTicketPageState();
}

class _CloseTicketPageState extends State<CloseTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _solutionController = TextEditingController();
  String _closureReason = TicketClosureReason.resolved;
  bool _isSaving = false;

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
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

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar atendimento'),
        content: const Text(
          'Confirma o encerramento deste chamado com a solução registrada? '
              'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finalizar')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await TicketService().resolveTicket(
        widget.ticket.id,
        solution: _solutionController.text.trim(),
        closureReason: _closureReason,
      );
      if (!mounted) return;
      // Volta direto para a Dashboard, removendo detalhe/fechamento da pilha.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorColor,
          content: Text('Não foi possível finalizar o atendimento. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Registrar Solução'),
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
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shortTicketId(widget.ticket.id),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.ticket.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: widget.ticket.status),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Descrição da solução',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _solutionController,
                  maxLines: 6,
                  decoration: _decoration('Descreva o que foi feito para resolver'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Descreva a solução aplicada'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text('Motivo do fechamento',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _closureReason,
                  decoration: _decoration('Motivo'),
                  items: TicketClosureReason.all
                      .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(TicketClosureReason.label(r)),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _closureReason = v ?? _closureReason),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _finish,
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Finalizar Atendimento'),
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