import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/course_card.dart';
import '../../widgets/custom_button.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          PremiumHeader(
            badge: 'Espace étudiant',
            title: 'Bonjour Sara 👋',
            subtitle: 'Retrouve tes cours, ton planning et les prochaines étapes pour progresser plus vite.',
            icon: Icons.school_rounded,
            bottom: Row(
              children: const [
                Expanded(
                  child: _HeaderMiniStat(value: 'B1', label: 'Niveau'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HeaderMiniStat(value: '4', label: 'Cours actifs'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HeaderMiniStat(value: '92%', label: 'Assiduité'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Vue rapide'),
                const SizedBox(height: 14),
                const DashboardCard(
                  value: 'Mercredi 18:30',
                  title: 'Prochain cours',
                  subtitle: 'Anglais professionnel avec Mme Amal — Salle 3B',
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 12),
                const DashboardCard(
                  value: '6 modules',
                  title: 'Progression de la semaine',
                  subtitle: 'Tu as validé 2 modules sur 6 dans ton parcours actuel.',
                  icon: Icons.trending_up_rounded,
                ),
                const SizedBox(height: 28),
                const SectionTitle('Actions rapides'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.quiz_rounded,
                        title: 'Test de niveau',
                        subtitle: 'Évaluer mes acquis',
                        onTap: onOpenLevelTest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.smart_toy_rounded,
                        title: 'Chatbot',
                        subtitle: 'Aide instantanée',
                        onTap: onOpenChatbot,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionTitle(
                  'Cours recommandés',
                  actionLabel: 'Voir tout',
                  onAction: () => onOpenCourseDetails('Français conversation'),
                ),
                const SizedBox(height: 14),
                CourseCard(
                  title: 'Anglais professionnel',
                  subtitle: 'Renforce ta communication en entreprise avec des mises en situation réelles.',
                  badge: 'En cours',
                  schedule: 'Lundi & mercredi • 18:30',
                  icon: Icons.business_center_rounded,
                  onTap: () => onOpenCourseDetails('Anglais professionnel'),
                ),
                const SizedBox(height: 12),
                CourseCard(
                  title: 'Français conversation',
                  subtitle: 'Travaille l’aisance orale, l’argumentation et l’expression naturelle.',
                  badge: 'Recommandé',
                  schedule: 'Samedi • 10:00',
                  icon: Icons.record_voice_over_rounded,
                  onTap: () => onOpenCourseDetails('Français conversation'),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Accompagnement'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu veux une progression plus rapide ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Passe le test de niveau puis demande une recommandation personnalisée via le chatbot.',
                        style: TextStyle(
                          height: 1.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Lancer mon plan personnalisé',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: onOpenChatbot,
                      ),
                    ],
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
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Icon(icon, color: AppColors.dark),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
