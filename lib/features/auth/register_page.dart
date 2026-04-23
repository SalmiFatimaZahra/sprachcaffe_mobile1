import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  final UserRole selectedRole;

  const RegisterPage({
    super.key,
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(selectedRole.icon, color: AppColors.dark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Créer un compte ${selectedRole.label.toLowerCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Inscription rapide',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Le rôle reste séparé dès l’inscription pour t’éviter de refaire toute la navigation plus tard.',
                style: const TextStyle(
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 26),
              const CustomTextField(
                label: 'Nom complet',
                hintText: 'Ex. Sara Benali',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Email',
                hintText: 'nom@academy.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Mot de passe',
                hintText: 'Créer un mot de passe',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Confirmer le mot de passe',
                hintText: 'Retape le mot de passe',
                prefixIcon: Icons.verified_user_outlined,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              CustomButton(
                label: 'Créer mon espace',
                icon: Icons.check_rounded,
                onPressed: () => AppNavigator.openDashboard(context, selectedRole),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'J’ai déjà un compte',
                outlined: true,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LoginPage(selectedRole: selectedRole),
                    ),
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
