import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final UserRole selectedRole;

  const RegisterPage({
    super.key,
    required this.selectedRole,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'student';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.admin:
        return 'admin';
    }
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Veuillez remplir tous les champs.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        _showMessage('Impossible de créer l’utilisateur.');
        return;
      }

      await user.updateDisplayName(name);
      const role = 'student';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Compte créé avec succès.');

      AppNavigator.openDashboard(context, widget.selectedRole);
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue.';

      if (e.code == 'email-already-in-use') {
        message = 'Cet email est déjà utilisé.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresse email invalide.';
      } else if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'La connexion Email/Mot de passe n’est pas activée dans Firebase.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              const Text(
                'Le rôle reste séparé dès l’inscription pour t’éviter de refaire toute la navigation plus tard.',
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 26),
              CustomTextField(
                controller: _nameController,
                label: 'Nom complet',
                hintText: 'Ex. Sara Benali',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
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
                hintText: 'Créer un mot de passe',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirmer le mot de passe',
                hintText: 'Retape le mot de passe',
                prefixIcon: Icons.verified_user_outlined,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              CustomButton(
                label: _isLoading ? 'Création...' : 'Créer mon espace',
                icon: Icons.check_rounded,
                onPressed: _isLoading ? null : _createAccount,
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'J’ai déjà un compte',
                outlined: true,
                onPressed: _isLoading
                    ? null
                    : () {
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