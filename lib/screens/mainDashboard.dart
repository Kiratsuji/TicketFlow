import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'colors/appColors.dart';
import '../widgets/navbar.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  String _role = 'user';
  String _username = 'Usuário';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Usamos snapshots() para ouvir em tempo real. Assim que o cadastro gravar no banco,
      // o dashboard vai perceber e carregar os dados.
      FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _role = doc.data()?['role'] ?? 'user';
            _username = doc.data()?['username'] ?? 'Usuário';
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    // Aqui fazemos o switch baseado no perfil
    switch (_role) {
      case 'admin':
        return _AdminDashboardView(username: _username);
      case 'tech':
        return const Center(child: Text('Dashboard do Técnico'));
      default:
        return const Center(child: Text('Dashboard do Usuário'));
    }
  }
}

// --- VIEW ESPECÍFICA DO ADMIN ---
class _AdminDashboardView extends StatelessWidget {
  final String username;
  const _AdminDashboardView({required this.username});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: Text(username[0].toUpperCase(), 
                        style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Administrador', style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 12)),
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
            const SizedBox(height: 24),

            // --- STATS CARDS ---
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Chamados abertos',
                    value: '12',
                    subtitle: 'No mês',
                    icon: Icons.confirmation_number_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Tempo médio',
                    value: '2.5h',
                    subtitle: 'Resolução',
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- MEUS CHAMADOS (TABELA/LISTA MAIOR) ---
            const Text('Meus Chamados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'Todos', isSelected: true),
                        _FilterChip(label: 'Administradores'),
                        _FilterChip(label: 'Técnicos'),
                        _FilterChip(label: 'Usuários'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileItem(name: 'João Silva', role: 'Técnico', status: 'Ativo'),
                  _ProfileItem(name: 'Maria Souza', role: 'Usuário', status: 'Inativo'),
                  _ProfileItem(name: 'Carlos Lima', role: 'Admin', status: 'Ativo'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- CHAMADOS RECENTES ---
            const Text('Chamados Recentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _RecentTicketItem(
              problem: 'Erro no sistema de pagamentos ao tentar finalizar compra.',
              status: 'Agendamento',
            ),
            _RecentTicketItem(
              problem: 'Impressora não conecta no Wi-Fi do escritório central.',
              status: 'Agendado',
            ),
          ],
        ),
      ),
    );
  }
}

// --- COMPONENTES AUXILIARES ---

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(subtitle, style: const TextStyle(color: AppColors.secondaryTextColor, fontSize: 10)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : AppColors.inputFillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String name, role, status;
  const _ProfileItem({required this.name, required this.role, required this.status});

  @override
  Widget build(BuildContext context) {
    bool isActive = status == 'Ativo';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: AppColors.inputFillColor, child: const Icon(Icons.person, size: 16, color: AppColors.secondaryTextColor)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(role, style: const TextStyle(color: AppColors.secondaryTextColor, fontSize: 11)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.successColor.withOpacity(0.1) : AppColors.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(color: isActive ? AppColors.successColor : AppColors.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RecentTicketItem extends StatelessWidget {
  final String problem, status;
  const _RecentTicketItem({required this.problem, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(problem, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: const TextStyle(color: AppColors.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
