import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
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
          final paymentRate = _percent(
            stats?.paidStudentsCount ?? 0,
            stats?.studentsCount ?? 0,
          );
          final assignmentRate = _percent(
            stats?.assignedStudentsCount ?? 0,
            stats?.studentsCount ?? 0,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const PremiumHeader(
                  badge: 'Rapports',
                  title: 'Vision décisionnelle',
                  subtitle:
                  'Indicateurs calculés depuis Firestore pour suivre l’activité réelle de la plateforme.',
                  icon: Icons.bar_chart_rounded,
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
                        const _ReportBox(
                          label: 'Erreur',
                          value:
                          'Impossible de charger les rapports. Vérifie Firestore.',
                          danger: true,
                        )
                      else ...[
                          DashboardCard(
                            value: '$paymentRate%',
                            title: 'Taux de paiement étudiants',
                            subtitle:
                            '${stats?.paidStudentsCount ?? 0} étudiants payés sur ${stats?.studentsCount ?? 0}.',
                            icon: Icons.payments_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '$assignmentRate%',
                            title: 'Affectation pédagogique',
                            subtitle:
                            '${stats?.assignedStudentsCount ?? 0} affectations dans teacher_students.',
                            icon: Icons.groups_rounded,
                          ),
                          const SizedBox(height: 28),
                          const SectionTitle('Résumé exécutif'),
                          const SizedBox(height: 14),
                          _ReportBox(
                            label: 'Utilisateurs totaux',
                            value:
                            '${stats?.usersCount ?? 0} comptes: ${stats?.studentsCount ?? 0} étudiants, ${stats?.teachersCount ?? 0} profs, ${stats?.adminsCount ?? 0} admins.',
                          ),
                          _ReportBox(
                            label: 'Catalogue',
                            value:
                            '${stats?.coursesCount ?? 0} cours créés, dont ${stats?.activeCoursesCount ?? 0} actifs.',
                          ),
                          _ReportBox(
                            label: 'Planification',
                            value:
                            '${stats?.sessionsCount ?? 0} séances enregistrées dans la collection sessions.',
                          ),
                          _ReportBox(
                            label: 'Ressources pédagogiques',
                            value:
                            '${stats?.resourcesCount ?? 0} documents partagés par les professeurs.',
                          ),
                          _ReportBox(
                            label: 'Paiements en attente',
                            value:
                            '${stats?.pendingPaymentsCount ?? 0} étudiants doivent encore valider le paiement.',
                            danger: (stats?.pendingPaymentsCount ?? 0) > 0,
                          ),
                          const SizedBox(height: 28),
                          const SectionTitle('Cours les plus affectés'),
                          const SizedBox(height: 14),
                          _CourseAssignmentReport(adminService: _adminService),
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

class _CourseAssignmentReport extends StatelessWidget {
  final AdminService adminService;

  const _CourseAssignmentReport({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: adminService.getCoursesStream(),
      builder: (context, coursesSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: adminService.getUsersStream(),
          builder: (context, usersSnapshot) {
            if (coursesSnapshot.connectionState == ConnectionState.waiting ||
                usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (coursesSnapshot.hasError || usersSnapshot.hasError) {
              return const _ReportBox(
                label: 'Erreur',
                value: 'Impossible de calculer ce bloc.',
                danger: true,
              );
            }

            final courses = coursesSnapshot.data?.docs ?? [];
            final courseLines = courses.map((doc) {
              final data = doc.data();
              final count = int.tryParse(_text(data['studentsCount'])) ?? 0;
              return MapEntry(_text(data['title']).isEmpty ? 'Cours sans titre' : _text(data['title']), count);
            }).toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (courseLines.isEmpty) {
              return const _ReportBox(
                label: 'Aucune donnée',
                value: 'Aucun cours trouvé pour générer le classement.',
              );
            }

            return Column(
              children: courseLines.take(5).map((entry) {
                return _ReportBox(
                  label: entry.key,
                  value: '${entry.value} étudiants déclarés dans le cours.',
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _ReportBox extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _ReportBox({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: danger ? Colors.red.shade100 : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: danger ? Colors.red.shade800 : AppColors.mutedText,
                height: 1.4,
                fontWeight: danger ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _percent(int value, int total) {
  if (total <= 0) return 0;
  return ((value / total) * 100).round();
}

String _text(dynamic value) => value?.toString().trim() ?? '';
