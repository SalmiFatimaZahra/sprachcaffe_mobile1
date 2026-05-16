import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_page.dart';


class LoginPage extends StatefulWidget {
  final UserRole selectedRole;

  const LoginPage({
    super.key,
    required this.selectedRole,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  UserRole? _roleFromString(String role) {
    switch (role) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.login(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;

      if (uid == null) {
        _showMessage('Impossible de récupérer l’utilisateur.');
        return;
      }

      final roleString = await _authService.getUserRole(uid);

      if (roleString == null) {
        _showMessage('Aucun rôle trouvé pour cet utilisateur.');
        return;
      }

      final userRole = _roleFromString(roleString);

      if (userRole == null) {
        _showMessage('Rôle invalide dans la base de données.');
        return;
      }

      if (!mounted) return;

      AppNavigator.openDashboard(context, userRole);
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur de connexion.';

      if (e.code == 'user-not-found') {
        message = 'Aucun compte trouvé avec cet email.';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresse email invalide.';
      } else if (e.code == 'invalid-credential') {
        message = 'Email ou mot de passe incorrect.';
      } else if (e.code == 'user-disabled') {
        message = 'Ce compte a été désactivé.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Erreur inconnue. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Entrez votre email avant de réinitialiser le mot de passe.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Email de réinitialisation envoyé.');
    } on FirebaseAuthException catch (e) {
      String message = 'Impossible d’envoyer l’email.';

      if (e.code == 'invalid-email') {
        message = 'Adresse email invalide.';
      } else if (e.code == 'user-not-found') {
        message = 'Aucun compte trouvé avec cet email.';
      }

      _showMessage(message);
    } catch (_) {
      _showMessage('Erreur inconnue. Réessayez.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = widget.selectedRole;

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
                'Connexion',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connecte-vous avec votre email et votre mot de passe.',
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 26),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'nom@academy.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: _isLoading
                    ? 'Connexion...'
                    : 'Accéder au tableau de bord',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: 12),

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
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterPage(
                              selectedRole: selectedRole,
                            ),
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