import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/userModel.dart';
import '../../services/userService.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';
import 'createUserPage.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
        future: UserService().getUser(uid),
        builder: (context, userSnap){
          if(!userSnap.hasData){
            return const Center(child: CircularProgressIndicator());
          }
          final companyId = userSnap.data!.companyId;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Usuários',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Expanded(
                    child: StreamBuilder<List<AppUser>>(
                      stream: UserService().streamUsers(companyId),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const EmptyState(message: 'Erro ao carregar usuários.');
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final users = snap.data!;
                        if (users.isEmpty) {
                          return const EmptyState(message: 'Nenhum usuário cadastrado.');
                        }
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (_, i) => _UserTile(user: users[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

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
        ],
      ),
    );
  }
}