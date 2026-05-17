import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final name = data["name"] ?? "Étudiant";
        final email = data["email"] ?? "";
        final level = data["level"] ?? "A0";
        final course = data["course"] ?? "Non défini";

        return SingleChildScrollView(
          child: Column(
            children: [

              PremiumHeader(
                badge: 'Profil',
                title: 'Mon compte étudiant',
                subtitle:
                'Gère tes informations personnelles et ton apprentissage.',
                icon: Icons.person_rounded,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SectionTitle('Informations'),
                    const SizedBox(height: 14),

                    _infoCard(name, email, level, course),

                    const SizedBox(height: 28),

                    const SectionTitle('Préférences'),
                    const SizedBox(height: 14),

                    _preferencesCard(),

                    const SizedBox(height: 24),

                    CustomButton(
                      label: 'Se déconnecter',
                      outlined: true,
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

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
      },
    );
  }

  Widget _infoCard(
      String name,
      String email,
      String level,
      String course,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ProfileLine(label: 'Nom', value: name),
          const SizedBox(height: 14),
          _ProfileLine(label: 'Email', value: email),
          const SizedBox(height: 14),
          _ProfileLine(label: 'Niveau', value: level),
          const SizedBox(height: 14),
          _ProfileLine(label: 'Cours', value: course),
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