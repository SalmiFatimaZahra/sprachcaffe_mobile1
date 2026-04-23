import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentCourseDetailsPage extends StatelessWidget {
  final String courseTitle;

  const StudentCourseDetailsPage({
    super.key,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PremiumHeader(
              badge: 'Détail du cours',
              title: courseTitle,
              subtitle: 'Une fiche structurée pour que tu puisses brancher ensuite les vraies données sans refaire l’UI.',
              icon: Icons.auto_stories_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardCard(
                    value: '12 semaines',
                    title: 'Durée du parcours',
                    subtitle: 'Programme découpé en modules avec exercices et suivi régulier.',
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 12),
                  const DashboardCard(
                    value: 'Coach dédié',
                    title: 'Accompagnement',
                    subtitle: 'Feedback sur la progression et recommandations personnalisées.',
                    icon: Icons.support_agent_rounded,
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Ce que tu vas travailler'),
                  const SizedBox(height: 14),
                  const _BulletTile(text: 'Compréhension orale et écrite'),
                  const _BulletTile(text: 'Expression professionnelle'),
                  const _BulletTile(text: 'Vocabulaire contextualisé'),
                  const _BulletTile(text: 'Mises en situation et corrections'),
                  const SizedBox(height: 28),
                  const SectionTitle('Organisation'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoLine(label: 'Format', value: 'Groupe + ressources digitales'),
                        SizedBox(height: 14),
                        _InfoLine(label: 'Rythme', value: '2 séances par semaine'),
                        SizedBox(height: 14),
                        _InfoLine(label: 'Suivi', value: 'Quiz, devoirs et feedback continu'),
                        SizedBox(height: 14),
                        _InfoLine(label: 'Validation', value: 'Projet final + test de niveau'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Demander une orientation',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Branche ici la demande d’orientation ou l’inscription.'),
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
  }
}

class _BulletTile extends StatelessWidget {
  final String text;

  const _BulletTile({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
