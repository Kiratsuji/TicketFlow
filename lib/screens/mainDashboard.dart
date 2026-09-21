import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/userModel.dart';
import '../widgets/navbar.dart';
import 'admin/adminHomePage.dart';
import 'admin/usersPage.dart';
import 'pages/profilePage.dart';
import 'pages/placeholderPage.dart';
import 'tech/openTicketsPage.dart';
import 'tech/techHomePage.dart';
import 'user/userHomePage.dart';

class _DashboardTab {
  final NavItem item;
  final Widget page;
  const _DashboardTab(this.item, this.page);
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _Loading();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Scaffold(
              body: Center(child: Text('Erro ao carregar seus dados.')));
        }
        if (!snap.hasData || !snap.data!.exists) return const _Loading();

        final data = snap.data!.data() ?? {};
        final role = data['role'] ?? UserRole.user;
        final username = data['username'] ?? 'Usuário';
        final email = data['email'] ?? user.email ?? '';

        final tabs = _tabsFor(role, username, email);
        final index = _currentIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: index,
            children: tabs.map((t) => t.page).toList(),
          ),
          bottomNavigationBar: CustomNavBar(
            items: tabs.map((t) => t.item).toList(),
            currentIndex: index,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        );
      },
    );
  }

  List<_DashboardTab> _tabsFor(String role, String username, String email) {
    final profile = _DashboardTab(
      const NavItem(label: 'Perfil', icon: Icons.person_rounded),
      ProfilePage(username: username, email: email, role: role),
    );

    switch (role) {
      case UserRole.admin:
        return [
          _DashboardTab(
            const NavItem(label: 'Início', icon: Icons.home_rounded),
            AdminHomePage(username: username),
          ),
          const _DashboardTab(
            NavItem(label: 'Usuários', icon: Icons.people_alt_rounded),
            UsersPage(),
          ),
          const _DashboardTab(
            NavItem(label: 'Chamados', icon: Icons.confirmation_number_rounded),
            PlaceholderPage(title: 'Todos os chamados'),
          ),
          const _DashboardTab(
            NavItem(label: 'Relatório', icon: Icons.bar_chart_rounded),
            PlaceholderPage(title: 'Relatórios'),
          ),
          profile,
        ];
      case UserRole.tech:
        return [
          _DashboardTab(
            const NavItem(label: 'Início', icon: Icons.home_rounded),
            TechHomePage(username: username),
          ),
          const _DashboardTab(
            NavItem(label: 'Abertos', icon: Icons.confirmation_number_rounded),
            OpenTicketsPage(),
          ),
          profile,
        ];
      default:
        return [
          _DashboardTab(
            const NavItem(label: 'Início', icon: Icons.home_rounded),
            UserHomePage(username: username),
          ),
          profile,
        ];
    }
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}