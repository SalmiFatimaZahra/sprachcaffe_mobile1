import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentPlanningPage extends StatelessWidget {
  const StudentPlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text("Utilisateur introuvable"));
          }

          final userData =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};

          final groupName = userData["groupName"] ?? "";

          if (groupName.isEmpty) {
            return const Center(
              child: Text("Aucun groupe assigné à cet utilisateur"),
            );
          }

          final sessionsStream = FirebaseFirestore.instance
              .collection("sessions")
              .where("groupName", isEqualTo: groupName)
              .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: sessionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Erreur de chargement"));
              }

              final sessions = snapshot.data?.docs ?? [];

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const PremiumHeader(
                      badge: 'Planning',
                      title: 'Mon agenda de formation',
                      subtitle:
                      'Une vue claire des séances, ateliers et rendez-vous à venir.',
                      icon: Icons.calendar_month_rounded,
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('Cette semaine'),
                          const SizedBox(height: 14),

                          if (sessions.isEmpty)
                            const Text("Aucune session planifiée"),

                          ...sessions.map((doc) {
                            final data =
                            doc.data() as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PlanningTile(
                                day: data["date"] ?? "-",
                                hour: data["time"] ?? "-",
                                title: data["courseTitle"] ?? "-",
                                location: data["room"] ?? "-",
                              ),
                            );
                          }),

                          const SizedBox(height: 28),

                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .doc(uid)
                                .snapshots(),
                            builder: (context, userSnap2) {
                              if (!userSnap2.hasData) {
                                return const SizedBox();
                              }

                              final data =
                                  userSnap2.data!.data()
                                  as Map<String, dynamic>? ??
                                      {};

                              final testCompleted =
                                  data["testCompleted"] == true;

                              if (testCompleted) {
                                return const SizedBox();
                              }

                              return const _ReminderCard(
                                title: 'Test de niveau',
                                subtitle:
                                'À compléter pour activer ton parcours',
                                icon: Icons.quiz_rounded,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ================= TILE =================
class _PlanningTile extends StatelessWidget {
  final String day;
  final String hour;
  final String title;
  final String location;

  const _PlanningTile({
    required this.day,
    required this.hour,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(day,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark)),
                const SizedBox(height: 4),
                Text(hour,
                    style: const TextStyle(
                        color: AppColors.mutedText)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark)),
                const SizedBox(height: 6),
                Text(location,
                    style: const TextStyle(
                        color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= REMINDER =================
class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.dark),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.mutedText),
      ),
    );
  }
}