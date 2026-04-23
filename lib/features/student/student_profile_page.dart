import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Profil',
            title: 'Mon compte étudiant',
            subtitle: 'Centralise ici les informations personnelles, préférences et paramètres de suivi.',
            icon: Icons.person_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Informations'),
                const SizedBox(height: 14),
                _infoCard(),
                const SizedBox(height: 28),
                const SectionTitle('Préférences'),
                const SizedBox(height: 14),
                _preferencesCard(),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Se déconnecter',
                  outlined: true,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(
                          selectedRole: UserRole.student,
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _ProfileLine(label: 'Nom', value: 'Sara Benali'),
          SizedBox(height: 14),
          _ProfileLine(label: 'Email', value: 'sara@academy.com'),
          SizedBox(height: 14),
          _ProfileLine(label: 'Niveau actuel', value: 'B1'),
          SizedBox(height: 14),
          _ProfileLine(label: 'Parcours', value: 'Anglais professionnel'),
        ],
      ),
    );
  }

  Widget _preferencesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _PreferenceRow(title: 'Notifications de cours'),
          Divider(height: 28),
          _PreferenceRow(title: 'Rappels de devoirs'),
          Divider(height: 28),
          _PreferenceRow(title: 'Mode compact'),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileLine({
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

class _PreferenceRow extends StatelessWidget {
  final String title;

  const _PreferenceRow({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        Switch(
          value: true,
          activeThumbColor: AppColors.dark,
          activeTrackColor: AppColors.primary,
          onChanged: (_) {},
        ),
      ],
    );
  }
}
