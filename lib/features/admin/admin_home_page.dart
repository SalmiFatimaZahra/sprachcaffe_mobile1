import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AdminService _adminService = AdminService();
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _adminService.getDashboardStats();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _adminService.getDashboardStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<AdminStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const PremiumHeader(
                  badge: 'Espace administrateur',
                  title: 'Pilotage global',
                  subtitle:
                  'Supervision complète de la plateforme : utilisateurs, cours, paiements, séances et ressources.',
                  icon: Icons.admin_panel_settings_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          stats == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (snapshot.hasError)
                        _ErrorBox(
                          message:
                          'Impossible de charger les statistiques. Vérifie les règles Firestore et la connexion.',
                          onRetry: _refresh,
                        )
                      else ...[
                          const SectionTitle('KPIs principaux'),
                          const SizedBox(height: 14),
                          DashboardCard(
                            value: '${stats?.studentsCount ?? 0}',
                            title: 'Étudiants inscrits',
                            subtitle:
                            '${stats?.paidStudentsCount ?? 0} payés • ${stats?.pendingPaymentsCount ?? 0} paiements en attente.',
                            icon: Icons.school_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '${stats?.teachersCount ?? 0}',
                            title: 'Professeurs',
                            subtitle:
                            'Comptes enseignants avec accès à la gestion pédagogique.',
                            icon: Icons.co_present_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '${stats?.coursesCount ?? 0}',
                            title: 'Cours au catalogue',
                            subtitle:
                            '${stats?.activeCoursesCount ?? 0} actifs • ${stats?.assignedStudentsCount ?? 0} affectations prof/étudiant.',
                            icon: Icons.menu_book_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '${stats?.sessionsCount ?? 0}',
                            title: 'Séances planifiées',
                            subtitle:
                            '${stats?.resourcesCount ?? 0} ressources pédagogiques partagées.',
                            icon: Icons.event_available_rounded,
                          ),
                          const SizedBox(height: 28),
                          const SectionTitle('Derniers utilisateurs'),
                          const SizedBox(height: 14),
                          if (stats == null || stats.latestUsers.isEmpty)
                            const _EmptyBox(
                              text: 'Aucun utilisateur trouvé pour le moment.',
                            )
                          else
                            ...stats.latestUsers.map((doc) {
                              final data = doc.data();
                              return _MiniItem(
                                title: AdminService.displayName(data),
                                subtitle:
                                '${_roleLabel(data['role'])} • ${AdminService.displayEmail(data)}',
                                icon: _roleIcon(data['role']),
                              );
                            }),
                          const SizedBox(height: 28),
                          const SectionTitle('Derniers cours'),
                          const SizedBox(height: 14),
                          if (stats == null || stats.latestCourses.isEmpty)
                            const _EmptyBox(text: 'Aucun cours ajouté.'),
                          if (stats != null)
                            ...stats.latestCourses.map((doc) {
                              final data = doc.data();
                              return _MiniItem(
                                title: _text(data['title'], 'Cours sans titre'),
                                subtitle:
                                '${_text(data['level'], 'Niveau non défini')} • ${_text(data['teacherEmail'], 'Prof non affecté')}',
                                icon: Icons.menu_book_rounded,
                              );
                            }),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MiniItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(icon, color: AppColors.dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.mutedText),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

String _text(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _roleLabel(dynamic role) {
  switch (_text(role, '').toLowerCase()) {
    case 'student':
      return 'Étudiant';
    case 'teacher':
      return 'Prof';
    case 'admin':
      return 'Administrateur';
    default:
      return 'Rôle non défini';
  }
}

IconData _roleIcon(dynamic role) {
  switch (_text(role, '').toLowerCase()) {
    case 'student':
      return Icons.school_rounded;
    case 'teacher':
      return Icons.co_present_rounded;
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    default:
      return Icons.person_rounded;
  }
}
