import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherPlanningPage extends StatelessWidget {
  const TeacherPlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    const schedule = [
      {
        'day': 'Lundi',
        'hour': '18:30',
        'title': 'Anglais professionnel A',
      },
      {
        'day': 'Mardi',
        'hour': '17:00',
        'title': 'Espagnol débutant',
      },
      {
        'day': 'Mercredi',
        'hour': '18:30',
        'title': 'Anglais professionnel A',
      },
      {
        'day': 'Samedi',
        'hour': '10:00',
        'title': 'Français conversation',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Planning enseignant',
            title: 'Organisation pédagogique',
            subtitle: 'Suivi des séances, rappels et préparation de la semaine.',
            icon: Icons.event_note_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Semaine en cours'),
                const SizedBox(height: 14),
                ...schedule.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          item['hour']!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      title: Text(
                        item['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      subtitle: Text(
                        item['day']!,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
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
