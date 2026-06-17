import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentCourseDetailsPage extends StatelessWidget {
  final String courseId;

  const StudentCourseDetailsPage({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("courses")
          .doc(courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("📌 Cours introuvable")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        // ================= SAFE FIELDS =================
        final String title = (data["title"] ?? data["langue"] ?? "Cours").toString();
        final String description = (data["description"] ?? "Aucune description").toString();
        final String duration = (data["duration"] ?? "-").toString();
        final String teacher = (data["teacherEmail"] ?? "Non défini").toString();
        final String format = (data["format"] ?? "-").toString();
        final String schedule = (data["schedule"] ?? data["horaire"] ?? "-").toString();
        final String validation = (data["validation"] ?? "-").toString();
        final String level = (data["level"] ?? data["niveau"] ?? "-").toString();

        // ================= OBJECTIVES =================
        final List<String> objectives = [];

        if (data["objectives"] is List) {
          objectives.addAll(List<String>.from(data["objectives"]));
        } else if (data["objectives"] is String) {
          objectives.add(data["objectives"]);
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                PremiumHeader(
                  badge: 'Détail du cours',
                  title: title,
                  subtitle: description,
                  icon: Icons.auto_stories_rounded,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= DASHBOARD =================
                      DashboardCard(
                        value: duration,
                        title: 'Durée du parcours',
                        subtitle: 'Informations du cours',
                        icon: Icons.schedule_rounded,
                      ),

                      const SizedBox(height: 12),

                      DashboardCard(
                        value: teacher,
                        title: 'Enseignant',
                        subtitle: 'Responsable du cours',
                        icon: Icons.person_rounded,
                      ),

                      const SizedBox(height: 28),

                      // ================= OBJECTIVES =================
                      const SectionTitle('Ce que tu vas travailler'),
                      const SizedBox(height: 14),

                      if (objectives.isEmpty)
                        const Text(
                          "Aucun objectif défini pour ce cours",
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...objectives.map(
                              (e) => _BulletTile(text: e),
                        ),

                      const SizedBox(height: 28),

                      // ================= ORGANISATION =================
                      const SectionTitle('Organisation'),
                      const SizedBox(height: 14),

                      _InfoBox(label: "Format", value: format),
                      _InfoBox(label: "Rythme", value: schedule),
                      _InfoBox(label: "Validation", value: validation),
                      _InfoBox(label: "Niveau", value: level),

                      const SizedBox(height: 30),

                      // ================= ACTION =================
                      CustomButton(
                        label: 'Demander une orientation',
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Chatbot : question sur "$title"',
                              ),
                            ),
                          );
                        },
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

// ================= INFO BOX =================
class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= BULLET =================
class _BulletTile extends StatelessWidget {
  final String text;

  const _BulletTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}