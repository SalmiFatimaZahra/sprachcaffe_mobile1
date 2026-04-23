import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Profil administrateur',
            title: 'Compte de supervision',
            subtitle: 'Paramètres globaux, identité, sécurité et préférences d’administration.',
            icon: Icons.person_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      _ProfileRow(label: 'Nom', value: 'Yassine Haddou'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Email', value: 'admin@academy.com'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Rôle', value: 'Administrateur'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Périmètre', value: 'Gestion complète'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Se déconnecter',
                  outlined: true,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(
                          selectedRole: UserRole.admin,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }
}
