import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const students = [
      {
        'name': 'Sara Benali',
        'status': 'Présente',
        'level': 'B1',
      },
      {
        'name': 'Youssef Tazi',
        'status': 'À suivre',
        'level': 'A2',
      },
      {
        'name': 'Lina Haddad',
        'status': 'Excellente progression',
        'level': 'B2',
      },
      {
        'name': 'Karim Alaoui',
        'status': 'Absence récente',
        'level': 'A2',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Étudiants',
            title: 'Suivi des apprenants',
            subtitle: 'Vue prête pour intégrer les présences, notes, commentaires et alertes pédagogiques.',
            icon: Icons.groups_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardCard(
                  value: '12',
                  title: 'Alertes pédagogiques',
                  subtitle: 'Étudiants nécessitant un suivi supplémentaire ou un rappel.',
                  icon: Icons.notification_important_rounded,
                ),
                const SizedBox(height: 28),
                const SectionTitle('Liste récente'),
                const SizedBox(height: 14),
                ...students.map(
                  (student) => Padding(
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
                          student['name']!.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      title: Text(
                        student['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      subtitle: Text(
                        '${student['status']} • Niveau ${student['level']}',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
