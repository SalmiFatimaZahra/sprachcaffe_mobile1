import 'package:flutter/material.dart';

import '../../widgets/dashboard_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Espace administrateur',
            title: 'Pilotage global',
            subtitle: 'Accède aux indicateurs clés, aux alertes et aux modules de gestion sans refaire l’architecture plus tard.',
            icon: Icons.admin_panel_settings_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionTitle('KPIs'),
                SizedBox(height: 14),
                DashboardCard(
                  value: '426',
                  title: 'Étudiants actifs',
                  subtitle: 'Répartis sur plusieurs parcours et niveaux.',
                  icon: Icons.school_rounded,
                ),
                SizedBox(height: 12),
                DashboardCard(
                  value: '22',
                  title: 'Enseignants',
                  subtitle: 'Profils actifs avec planning affecté.',
                  icon: Icons.co_present_rounded,
                ),
                SizedBox(height: 12),
                DashboardCard(
                  value: '37',
                  title: 'Cours au catalogue',
                  subtitle: 'Programmes standards, intensifs et certifiants.',
                  icon: Icons.menu_book_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
