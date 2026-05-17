import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';
import '../auth/login_page.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(
          selectedRole: UserRole.student,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName;
    final email = user?.email ?? 'Email non disponible';

    final displayName = name == null || name.isEmpty ? 'Professeur' : name;

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Profil enseignant',
            title: 'Mon profil',
            subtitle:
            'Consulte tes informations personnelles et gère ton accès à l’espace professeur.',
            icon: Icons.person_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeaderCard(
                  name: displayName,
                  email: email,
                ),
                const SizedBox(height: 26),

                const SectionTitle('Informations du compte'),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.035),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      _ProfileInfoRow(
                        icon: Icons.badge_rounded,
                        label: 'Rôle',
                        value: 'Professeur',
                      ),
                      SizedBox(height: 14),
                      _ProfileInfoRow(
                        icon: Icons.verified_rounded,
                        label: 'Statut',
                        value: 'Compte actif',
                      ),
                      SizedBox(height: 14),
                      _ProfileInfoRow(
                        icon: Icons.school_rounded,
                        label: 'Département',
                        value: 'Langues',
                      ),
                      SizedBox(height: 14),
                      _ProfileInfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Disponibilité',
                        value: 'Selon planning',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                const SectionTitle('Actions'),
                const SizedBox(height: 14),

                CustomButton(
                  label: 'Modifier mon profil',
                  icon: Icons.edit_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La modification du profil sera ajoutée après.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                CustomButton(
                  label: 'Se déconnecter',
                  outlined: true,
                  icon: Icons.logout_rounded,
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeaderCard({
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primary,
            child: Text(
              initials.isEmpty ? 'P' : initials,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Enseignant actif',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySoft,
          child: Icon(
            icon,
            size: 18,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}