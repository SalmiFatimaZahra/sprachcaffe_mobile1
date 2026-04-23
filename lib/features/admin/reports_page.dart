import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const reportLines = [
      {
        'label': 'Croissance inscriptions',
        'value': '+12% ce mois-ci',
      },
      {
        'label': 'Taux de présence global',
        'value': '89% sur 30 jours',
      },
      {
        'label': 'Satisfaction apprenants',
        'value': '4.7 / 5',
      },
      {
        'label': 'Cours les plus demandés',
        'value': 'Anglais professionnel, Français conversation',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Rapports',
            title: 'Vision décisionnelle',
            subtitle: 'Prépare une base claire pour brancher plus tard graphiques, exports et tableaux de bord dynamiques.',
            icon: Icons.bar_chart_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardCard(
                  value: '4.7 / 5',
                  title: 'Satisfaction moyenne',
                  subtitle: 'Indicateur clé consolidé sur les retours apprenants.',
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 28),
                const SectionTitle('Résumé exécutif'),
                const SizedBox(height: 14),
                ...reportLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              line['label']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              line['value']!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
