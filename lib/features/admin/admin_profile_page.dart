import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_header.dart';
import '../auth/login_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(selectedRole: UserRole.admin),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Profil administrateur',
            title: 'Compte de supervision',
            subtitle:
            'Identité, rôle, accès et sécurité du compte administrateur connecté.',
            icon: Icons.person_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              children: [
                if (user == null)
                  const _InfoBox(text: 'Aucun utilisateur connecté.')
                else
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _InfoBox(
                          text: 'Impossible de charger le profil admin.',
                          danger: true,
                        );
                      }

                      final data = snapshot.data?.data() ?? <String, dynamic>{};
                      final role = _text(data['role']).isEmpty
                          ? 'admin'
                          : _text(data['role']);

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _ProfileRow(
                              label: 'Nom',
                              value: AdminService.displayName({
                                ...data,
                                'email': data['email'] ?? user.email,
                              }),
                            ),
                            const SizedBox(height: 14),
                            _ProfileRow(
                              label: 'Email',
                              value: _text(data['email']).isEmpty
                                  ? user.email ?? 'Email non renseigné'
                                  : _text(data['email']),
                            ),
                            const SizedBox(height: 14),
                            _ProfileRow(label: 'Rôle', value: _roleLabel(role)),
                            const SizedBox(height: 14),
                            _ProfileRow(
                              label: 'Privilèges',
                              value: role.toLowerCase() == 'admin'
                                  ? 'Gestion complète'
                                  : 'Rôle à vérifier',
                            ),
                            const SizedBox(height: 14),
                            _ProfileRow(
                              label: 'UID Firebase',
                              value: user.uid,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Se déconnecter',
                  icon: Icons.logout_rounded,
                  outlined: true,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.mutedText,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool danger;

  const _InfoBox({required this.text, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: danger ? Colors.red.shade100 : AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: danger ? Colors.red.shade800 : AppColors.mutedText,
          fontWeight: danger ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _roleLabel(String role) {
  switch (role.toLowerCase()) {
    case 'student':
      return 'Étudiant';
    case 'teacher':
      return 'Prof';
    case 'admin':
      return 'Administrateur';
    default:
      return 'Rôle non défini';
  }
}
