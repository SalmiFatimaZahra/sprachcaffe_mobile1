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

  // 🔥 LOGOUT
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
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final name = data["name"] ?? "Étudiant";
        final level = data["level"] ?? "A0";
        final coursesCount = data["coursesCount"] ?? 0;
        final attendance = data["attendance"] ?? 0;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [

                // 🔥 HEADER
                PremiumHeader(
                  badge: 'Espace étudiant',
                  title: 'Bonjour $name 👋',
                  subtitle:
                  'Retrouve tes cours et ton évolution personnalisée.',
                  icon: Icons.school_rounded,
                  bottom: Row(
                    children: [
                      Expanded(
                        child: _HeaderMiniStat(
                          value: level,
                          label: 'Niveau',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeaderMiniStat(
                          value: '$coursesCount',
                          label: 'Cours',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeaderMiniStat(
                          value: '$attendance%',
                          label: 'Assiduité',
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔥 LOGOUT BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 10),
                    child: TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Déconnexion",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SectionTitle('Vue rapide'),
                      const SizedBox(height: 14),

                      DashboardCard(
                        value: "Mercredi 18:30",
                        title: "Prochain cours",
                        subtitle: "Anglais professionnel",
                        icon: Icons.schedule_rounded,
                      ),

                      const SizedBox(height: 12),

                      DashboardCard(
                        value: "Progression",
                        title: "Suivi",
                        subtitle: "Ton apprentissage est en cours",
                        icon: Icons.trending_up_rounded,
                      ),

                      const SizedBox(height: 28),

                      SectionTitle(
                        'Cours recommandés',
                        actionLabel: 'Voir tout',
                        onAction: () =>
                            onOpenCourseDetails('Français conversation'),
                      ),

                      const SizedBox(height: 14),

                      CourseCard(
                        title: 'Anglais professionnel',
                        subtitle: 'Business communication',
                        badge: 'En cours',
                        schedule: 'Lundi & mercredi',
                        icon: Icons.business_center_rounded,
                        onTap: () =>
                            onOpenCourseDetails('Anglais professionnel'),
                      ),

                      const SizedBox(height: 12),

                      CourseCard(
                        title: 'Français conversation',
                        subtitle: 'Expression orale',
                        badge: 'Recommandé',
                        schedule: 'Samedi',
                        icon: Icons.record_voice_over_rounded,
                        onTap: () =>
                            onOpenCourseDetails('Français conversation'),
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

class _HeaderMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderMiniStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.80),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}