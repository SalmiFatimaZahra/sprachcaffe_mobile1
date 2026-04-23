import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentPlanningPage extends StatelessWidget {
  const StudentPlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    const sessions = [
      {
        'day': 'Lundi',
        'hour': '18:30',
        'title': 'Anglais professionnel',
        'location': 'Salle 3B',
      },
      {
        'day': 'Mercredi',
        'hour': '18:30',
        'title': 'Anglais professionnel',
        'location': 'Salle 3B',
      },
      {
        'day': 'Samedi',
        'hour': '10:00',
        'title': 'Français conversation',
        'location': 'Atelier 2',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Planning',
            title: 'Mon agenda de formation',
            subtitle: 'Une vue claire des séances, ateliers, rendez-vous et échéances à venir.',
            icon: Icons.calendar_month_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Cette semaine'),
                const SizedBox(height: 14),
                ...sessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanningTile(
                      day: session['day']!,
                      hour: session['hour']!,
                      title: session['title']!,
                      location: session['location']!,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Rappels'),
                const SizedBox(height: 14),
                const _ReminderCard(
                  title: 'Quiz vocabulaire',
                  subtitle: 'À rendre avant jeudi 20:00',
                  icon: Icons.assignment_turned_in_rounded,
                ),
                const SizedBox(height: 12),
                const _ReminderCard(
                  title: 'Atelier conversation',
                  subtitle: 'Places limitées — inscription recommandée',
                  icon: Icons.groups_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hour,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.4,
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.mutedText,
          height: 1.4,
        ),
      ),
    );
  }
}
