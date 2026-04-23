import 'package:flutter/material.dart';

import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Mes classes',
            title: 'Cours et groupes',
            subtitle: 'Cette interface est pensée pour brancher ensuite facilement listes, absences, notes et contenus de séance.',
            icon: Icons.class_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionTitle('Groupes actifs'),
                SizedBox(height: 14),
                CourseCard(
                  title: 'Anglais professionnel — Groupe A',
                  subtitle: '24 étudiants • focus communication en entreprise',
                  badge: 'Actif',
                  schedule: 'Lundi & mercredi • 18:30',
                  icon: Icons.business_center_rounded,
                ),
                SizedBox(height: 12),
                CourseCard(
                  title: 'Français conversation — Groupe B',
                  subtitle: '18 étudiants • atelier oral et fluidité',
                  badge: 'Atelier',
                  schedule: 'Samedi • 10:00',
                  icon: Icons.record_voice_over_rounded,
                ),
                SizedBox(height: 12),
                CourseCard(
                  title: 'Espagnol débutant',
                  subtitle: '16 étudiants • bases et communication simple',
                  badge: 'Démarrage',
                  schedule: 'Mardi • 17:00',
                  icon: Icons.translate_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
