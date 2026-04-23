import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_page.dart';
import 'role_selection_page.dart';

class LoginPage extends StatelessWidget {
  final UserRole selectedRole;

  const LoginPage({
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
              _AuthTopBar(selectedRole: selectedRole),
              const SizedBox(height: 24),
              Text(
                'Connexion ${selectedRole.label.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'La structure est déjà prête pour les 3 rôles. Tu pourras brancher ton backend plus tard sans casser les écrans.',
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 26),
              const CustomTextField(
                label: 'Email',
                hintText: 'nom@academy.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Mot de passe',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ajoute ici la logique mot de passe oublié.'),
                      ),
                    );
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: 'Accéder au tableau de bord',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => AppNavigator.openDashboard(context, selectedRole),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Changer de rôle',
                outlined: true,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterPage(selectedRole: selectedRole),
                          ),
                        );
                      },
                      child: const Text('Créer un compte'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  final UserRole selectedRole;

  const _AuthTopBar({
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          child: Text(
            selectedRole.shortLabel,
            style: const TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            selectedRole.welcomeTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }
}
