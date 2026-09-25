import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/userModel.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class ProfilePage extends StatefulWidget {
  final String username, email, role;
  const ProfilePage({
    super.key,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _usernameController =
  TextEditingController(text: widget.username);
  final _usernameFormKey = GlobalKey<FormState>();
  bool _isSavingUsername = false;

  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.errorColor : null,
        content: Text(message),
      ),
    );
  }

  Future<void> _saveUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;
    final newName = _usernameController.text.trim();
    if (newName == widget.username) return;

    setState(() => _isSavingUsername = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updateDisplayName(newName);
      await user.reload();
      await UserService().updateUsername(user.uid, newName);
      _snack('Nome atualizado com sucesso!');
    } catch (e) {
      _snack('Não foi possível atualizar o nome. Tente novamente.',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSavingUsername = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email ?? widget.email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _snack('Senha alterada com sucesso!');
    } on FirebaseAuthException catch (e) {
      _snack(_mapPasswordError(e), isError: true);
    } catch (e) {
      _snack('Não foi possível alterar a senha. Tente novamente.',
          isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  String _mapPasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha atual incorreta.';
      case 'weak-password':
        return 'A nova senha precisa ter pelo menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Por segurança, saia e entre novamente antes de trocar a senha.';
      default:
        return e.message ?? 'Ocorreu um erro. Tente novamente.';
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.inputFillColor,
    prefixIcon: icon != null ? Icon(icon, size: 20) : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final memberSince = user?.metadata.creationTime;
    final emailVerified = user?.emailVerified ?? false;
    final initial = widget.username.isEmpty ? '?' : widget.username[0].toUpperCase();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Perfil'),

            // Cabeçalho com avatar (iniciais), nome e nível da conta.
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        InfoChip(
                          icon: Icons.shield_outlined,
                          label: UserRole.label(widget.role),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const SectionTitle('Informações da conta'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _usernameFormKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: _decoration('Nome',
                                icon: Icons.person_outline),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe um nome'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _isSavingUsername ? null : _saveUsername,
                            child: _isSavingUsername
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.check_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // E-mail: somente leitura (trocar e-mail exige um fluxo à
                  // parte de confirmação e não foi pedido aqui).
                  TextFormField(
                    initialValue: widget.email,
                    enabled: false,
                    decoration: _decoration('E-mail', icon: Icons.mail_outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        emailVerified
                            ? Icons.verified_outlined
                            : Icons.error_outline,
                        size: 14,
                        color: emailVerified
                            ? AppColors.successColor
                            : AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emailVerified ? 'E-mail verificado' : 'E-mail não verificado',
                        style: TextStyle(
                          fontSize: 12,
                          color: emailVerified
                              ? AppColors.successColor
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nível da conta: apenas visualização, não pode ser
                  // alterado por aqui.
                  TextFormField(
                    initialValue: UserRole.label(widget.role),
                    enabled: false,
                    decoration:
                    _decoration('Nível da conta', icon: Icons.shield_outlined),
                  ),

                  if (memberSince != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Membro desde ${formatDate(memberSince)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.secondaryTextColor),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),
            const SectionTitle('Alterar senha'),
            AppCard(
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: _decoration('Senha atual',
                          icon: Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Informe sua senha atual'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration:
                      _decoration('Nova senha', icon: Icons.lock_reset_outlined)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a nova senha';
                        if (v.length < 6) return 'Use pelo menos 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: _decoration('Confirmar nova senha',
                          icon: Icons.lock_reset_outlined)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _newPasswordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isChangingPassword ? null : _changePassword,
                        child: _isChangingPassword
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Alterar senha'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded, color: AppColors.errorColor),
                label: const Text('Sair',
                    style: TextStyle(color: AppColors.errorColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}