import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Profil enseignant',
            title: 'Mon espace professionnel',
            subtitle: 'Informations personnelles, disponibilité et paramètres liés à l’enseignement.',
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
                      _ProfileRow(label: 'Nom', value: 'Amal Idrissi'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Email', value: 'amal@academy.com'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Spécialité', value: 'Anglais & Français'),
                      SizedBox(height: 14),
                      _ProfileRow(label: 'Disponibilité', value: 'Lundi à samedi'),
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
                          selectedRole: UserRole.teacher,
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
