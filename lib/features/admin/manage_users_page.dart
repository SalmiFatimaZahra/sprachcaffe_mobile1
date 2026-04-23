import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const users = [
      {
        'name': 'Sara Benali',
        'role': 'Étudiant',
      },
      {
        'name': 'Amal Idrissi',
        'role': 'Prof',
      },
      {
        'name': 'Yassine Haddou',
        'role': 'Administrateur',
      },
      {
        'name': 'Karim Tazi',
        'role': 'Étudiant',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const PremiumHeader(
            badge: 'Gestion des utilisateurs',
            title: 'Comptes et rôles',
            subtitle: 'Base idéale pour brancher plus tard la gestion des permissions, validations et statuts.',
            icon: Icons.people_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Liste récente'),
                const SizedBox(height: 14),
                ...users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      tileColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          user['name']!.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      title: Text(
                        user['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      subtitle: Text(
                        user['role']!,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                      trailing: const Icon(Icons.edit_rounded),
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
