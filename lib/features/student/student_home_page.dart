import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../../widgets/course_card.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentHomePage extends StatelessWidget {
  final VoidCallback onOpenLevelTest;
  final VoidCallback onOpenChatbot;
  final void Function([String courseTitle]) onOpenCourseDetails;

  const StudentHomePage({
    super.key,
    required this.onOpenLevelTest,
    required this.onOpenChatbot,
    required this.onOpenCourseDetails,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(selectedRole: UserRole.student),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final name = data["name"] ?? "Étudiant";
        final level = data["level"] ?? "A0";
        final language = data["language"] ?? "Français";
        final coursesCount = data["coursesCount"] ?? 0;
        final attendance = data["attendance"] ?? 0;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [

                /// 🔥 HEADER
                PremiumHeader(
                  badge: 'Espace étudiant',
                  title: 'Bonjour $name 👋',
                  subtitle: 'Ton apprentissage personnalisé continue ici.',
                  icon: Icons.school_rounded,
                  bottom: Column(
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: _HeaderMiniStat(value: level, label: 'Niveau'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HeaderMiniStat(value: '$coursesCount', label: 'Cours'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HeaderMiniStat(value: '$attendance%', label: 'Assiduité'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// 🔥 LOGOUT BUTTON
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _logout(context),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Déconnexion",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔥 TEST DE NIVEAU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: onOpenLevelTest,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.dark],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [

                          const Icon(
                            Icons.quiz_rounded,
                            color: Colors.white,
                            size: 32,
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Test de niveau $language",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Évalue ton niveau automatiquement",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                /// 🔥 CONTENT
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SectionTitle('Vue rapide'),

                      const SizedBox(height: 14),

                      DashboardCard(
                        value: "Mercredi 18:30",
                        title: "Prochain cours",
                        subtitle: "Cours personnalisé",
                        icon: Icons.schedule_rounded,
                      ),

                      const SizedBox(height: 12),

                      DashboardCard(
                        value: "En progression",
                        title: "Suivi",
                        subtitle: "Ton apprentissage évolue chaque semaine",
                        icon: Icons.trending_up_rounded,
                      ),

                      const SizedBox(height: 28),

                      /// 🔥 ACTIONS
                      const SectionTitle('Actions rapides'),

                      const SizedBox(height: 14),

                      Row(
                        children: [

                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.smart_toy_rounded,
                              title: 'Chatbot',
                              subtitle: 'Assistant IA',
                              onTap: onOpenChatbot,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.menu_book_rounded,
                              title: 'Cours',
                              subtitle: 'Voir mes formations',
                              onTap: () => onOpenCourseDetails(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// 🔥 COURS
                      const SectionTitle('Cours recommandés'),

                      const SizedBox(height: 14),

                      CourseCard(
                        title: 'Anglais professionnel',
                        subtitle: 'Business communication',
                        badge: 'En cours',
                        schedule: 'Lundi & mercredi',
                        icon: Icons.business_center_rounded,
                        onTap: () => onOpenCourseDetails('Anglais professionnel'),
                      ),

                      const SizedBox(height: 12),

                      CourseCard(
                        title: 'Français conversation',
                        subtitle: 'Expression orale',
                        badge: 'Recommandé',
                        schedule: 'Samedi',
                        icon: Icons.record_voice_over_rounded,
                        onTap: () => onOpenCourseDetails('Français conversation'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// =====================
/// WIDGETS UI
/// =====================

class _HeaderMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderMiniStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(icon, color: AppColors.dark),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}