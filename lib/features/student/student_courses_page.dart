import 'package:flutter/material.dart';

import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentCoursesPage extends StatelessWidget {
  final void Function([String courseTitle]) onOpenCourseDetails;

  const StudentCoursesPage({
    super.key,
    required this.onOpenCourseDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Mes cours',
            title: 'Catalogue étudiant',
            subtitle: 'Retrouve les cours suivis, les recommandations et les formats disponibles selon ton rythme.',
            icon: Icons.menu_book_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Cours actifs'),
                const SizedBox(height: 14),
                CourseCard(
                  title: 'Anglais professionnel',
                  subtitle: 'Vocabulaire métier, e-mails, réunions et prises de parole.',
                  badge: 'Actif',
                  schedule: '2 séances / semaine',
                  icon: Icons.business_center_rounded,
                  onTap: () => onOpenCourseDetails('Anglais professionnel'),
                ),
                const SizedBox(height: 12),
                CourseCard(
                  title: 'Espagnol débutant',
                  subtitle: 'Bases de communication, grammaire essentielle et compréhension orale.',
                  badge: 'Nouveau',
                  schedule: 'Samedi • 14:00',
                  icon: Icons.translate_rounded,
                  onTap: () => onOpenCourseDetails('Espagnol débutant'),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Suggestions'),
                const SizedBox(height: 14),
                CourseCard(
                  title: 'Français conversation',
                  subtitle: 'Booste l’expression orale avec un programme conversation intensive.',
                  badge: 'Conseillé',
                  schedule: 'Atelier libre • mercredi',
                  icon: Icons.record_voice_over_rounded,
                  onTap: () => onOpenCourseDetails('Français conversation'),
                ),
                const SizedBox(height: 12),
                CourseCard(
                  title: 'Préparation TOEIC',
                  subtitle: 'Entraînement ciblé, mini-tests et stratégies pour gagner des points.',
                  badge: 'Objectif certif',
                  schedule: 'Session intensive • 6 semaines',
                  icon: Icons.workspace_premium_rounded,
                  onTap: () => onOpenCourseDetails('Préparation TOEIC'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
