import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../auth/role_selection_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF222C3A), AppColors.dark],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withOpacity(0.10),
                      ),
                      child: const Text(
                        'Version PFA prête à faire évoluer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Une seule app,\n3 espaces métiers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Commence avec une architecture claire dès maintenant pour ne pas refaire toute l’interface quand tu ajoutes le backend.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: const [
                        Expanded(
                          child: _TopStat(value: '3', label: 'Rôles'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _TopStat(value: '1', label: 'Design system'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _TopStat(value: '100%', label: 'Modulaire'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const DashboardCard(
                value: 'Étudiant',
                title: 'Suivi personnel',
                subtitle: 'Cours, planning, ressources, chatbot et test de niveau.',
                icon: Icons.school_rounded,
              ),
              const SizedBox(height: 14),
              const DashboardCard(
                value: 'Prof',
                title: 'Pilotage pédagogique',
                subtitle: 'Classes, séances, étudiants et préparation des cours.',
                icon: Icons.co_present_rounded,
              ),
              const SizedBox(height: 14),
              const DashboardCard(
                value: 'Admin',
                title: 'Gestion globale',
                subtitle: 'Utilisateurs, catalogue, indicateurs et décisions.',
                icon: Icons.admin_panel_settings_rounded,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Configurer mon accès',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Découvrir plus tard',
                outlined: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String value;
  final String label;

  const _TopStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
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
