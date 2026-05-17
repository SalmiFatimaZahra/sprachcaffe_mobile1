import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/course_service.dart';
import '../../services/session_service.dart';
import '../../services/student_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final CourseService _courseService = CourseService();
  final SessionService _sessionService = SessionService();
  final StudentService _studentService = StudentService();

  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, int>> _loadStats() async {
    final coursesCount = await _courseService.getMyCoursesCount();
    final sessionsCount = await _sessionService.getMySessionsCount();
    final studentsCount = await _studentService.getMyStudentsCount();

    return {
      'courses': coursesCount,
      'sessions': sessionsCount,
      'students': studentsCount,
    };
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName;
    final email = user?.email ?? '';

    final displayName =
    name == null || name.isEmpty ? 'Professeur' : name.split(' ').first;

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            PremiumHeader(
              badge: 'Espace enseignant',
              title: 'Bonjour $displayName ',
              subtitle:
              'Pilote tes cours, ton planning et le suivi de tes étudiants depuis un seul espace.',
              icon: Icons.co_present_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Vue rapide'),
                  const SizedBox(height: 14),
                  FutureBuilder<Map<String, int>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _InfoBox(
                          icon: Icons.error_outline_rounded,
                          title: 'Erreur de chargement',
                          subtitle: snapshot.error.toString(),
                        );
                      }

                      final stats = snapshot.data ??
                          {
                            'courses': 0,
                            'sessions': 0,
                            'students': 0,
                          };

                      final coursesCount = stats['courses'] ?? 0;
                      final sessionsCount = stats['sessions'] ?? 0;
                      final studentsCount = stats['students'] ?? 0;

                      return Column(
                        children: [
                          DashboardCard(
                            value: '$coursesCount',
                            title: 'Cours actifs',
                            subtitle:
                            'Cours créés et associés à ton compte professeur.',
                            icon: Icons.class_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '$sessionsCount',
                            title: 'Séances programmées',
                            subtitle:
                            'Séances ajoutées dans ton planning enseignant.',
                            icon: Icons.event_available_rounded,
                          ),
                          const SizedBox(height: 12),
                          DashboardCard(
                            value: '$studentsCount',
                            title: 'Étudiants suivis',
                            subtitle:
                            'Étudiants associés à ton espace professeur.',
                            icon: Icons.groups_rounded,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Prochaine étape'),
                  const SizedBox(height: 14),
                  const _InfoBox(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Ton espace professeur est connecté',
                    subtitle:
                    'Les cours, les séances et les étudiants sont maintenant lus depuis Firestore.',
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Actions rapides'),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: const [
                      _QuickActionCard(
                        title: 'Mes cours',
                        icon: Icons.class_rounded,
                      ),
                      _QuickActionCard(
                        title: 'Planning',
                        icon: Icons.event_note_rounded,
                      ),
                      _QuickActionCard(
                        title: 'Étudiants',
                        icon: Icons.groups_rounded,
                      ),
                      _QuickActionCard(
                        title: 'Ressources',
                        icon: Icons.folder_copy_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Compte connecté'),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              icon,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    height: 1.4,
                    color: AppColors.mutedText,
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _QuickActionCard({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.dark,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}