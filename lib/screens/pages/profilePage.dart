import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/userModel.dart';
import '../../widgets/appWidgets.dart';
import '../colors/appColors.dart';

class ProfilePage extends StatelessWidget {
  final String username, email, role;
  const ProfilePage({
    super.key,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Perfil'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(color: AppColors.secondaryTextColor)),
                  const SizedBox(height: 4),
                  Text(UserRole.label(role),
                      style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
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