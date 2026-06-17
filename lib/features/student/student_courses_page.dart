import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentCoursesPage extends StatelessWidget {
  final void Function(String courseId) onOpenCourseDetails;

  const StudentCoursesPage({
    super.key,
    required this.onOpenCourseDetails,
  });

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
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final List<Map<String, dynamic>> courses =
        List<Map<String, dynamic>>.from(
          (data["cours"] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );

        return SingleChildScrollView(
          child: Column(
            children: [
              const PremiumHeader(
                badge: 'Mes cours',
                title: 'Catalogue étudiant',
                subtitle:
                'Retrouve tes cours, ton progression et tes apprentissages.',
                icon: Icons.menu_book_rounded,
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Cours actifs'),
                    const SizedBox(height: 14),

                    // ================= COURSES USER =================
                    if (courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Aucun cours inscrit"),
                      )
                    else
                      ...courses.map((course) {
                        final courseId = course["courseId"] ??
                            course["id"] ??
                            course["langue"];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CourseCard(
                            title: course["langue"] ?? "Cours",
                            subtitle:
                            "${course["niveau"] ?? "Niveau"} • ${course["mode"] ?? ""}",
                            badge: "Actif",
                            schedule: course["horaire"] ?? "Planning flexible",
                            icon: Icons.school,
                            onTap: () => onOpenCourseDetails(courseId),
                          ),
                        );
                      }),

                    const SizedBox(height: 28),

                    const SectionTitle('Suggestions'),
                    const SizedBox(height: 14),

                    // ================= SUGGESTIONS (statique amélioré) =================
                    _SuggestionCard(
                      title: 'Français conversation',
                      subtitle:
                      'Améliore ton expression orale avec des dialogues réels.',
                      badge: 'Conseillé',
                      schedule: 'Atelier libre',
                      icon: Icons.record_voice_over_rounded,
                      onTap: () =>
                          onOpenCourseDetails("FR_CONVERSATION_ID"),
                    ),

                    const SizedBox(height: 12),

                    _SuggestionCard(
                      title: 'Préparation TOEIC',
                      subtitle:
                      'Entraînement intensif + tests blancs.',
                      badge: 'Certification',
                      schedule: '6 semaines',
                      icon: Icons.workspace_premium_rounded,
                      onTap: () => onOpenCourseDetails("TOEIC_ID"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================= SUGGESTION CARD =================
class _SuggestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String schedule;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.schedule,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CourseCard(
      title: title,
      subtitle: subtitle,
      badge: badge,
      schedule: schedule,
      icon: icon,
      onTap: onTap,
    );
  }
}