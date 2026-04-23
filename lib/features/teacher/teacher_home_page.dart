import 'package:flutter/material.dart';

import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Espace enseignant',
            title: 'Bonjour Mme Amal 👋',
            subtitle: 'Consulte rapidement tes classes, le rythme de la semaine et les priorités pédagogiques.',
            icon: Icons.co_present_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionTitle('Indicateurs du jour'),
                SizedBox(height: 14),
                DashboardCard(
                  value: '4',
                  title: 'Séances prévues',
                  subtitle: 'Deux groupes B1, un atelier oral et une séance de rattrapage.',
                  icon: Icons.calendar_view_day_rounded,
                ),
                SizedBox(height: 12),
                DashboardCard(
                  value: '58',
                  title: 'Étudiants suivis',
                  subtitle: 'Répartis sur 5 groupes actifs cette semaine.',
                  icon: Icons.groups_rounded,
                ),
                SizedBox(height: 12),
                DashboardCard(
                  value: '91%',
                  title: 'Présence moyenne',
                  subtitle: 'Bon niveau d’assiduité sur les dernières séances.',
                  icon: Icons.fact_check_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
