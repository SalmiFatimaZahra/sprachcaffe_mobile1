import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_page.dart';
import '../student/student_register_page.dart';
import '../student/payment_page.dart';

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  UserRole? _roleFromString(String role) {
    switch (role) {
      case "student":
        return UserRole.student;
      case "teacher":
        return UserRole.teacher;
      case "admin":
        return UserRole.admin;
      default:
        return null;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔐 LOGIN FIREBASE AUTH
      final userCredential = await _authService.login(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 📦 GET USER FROM FIRESTORE
      final docRef =
      FirebaseFirestore.instance.collection("users").doc(uid);

      final doc = await docRef.get();

      // Aucun document Firestore = compte non validé par la logique métier.
      // Les étudiants passent par RegisterPage, les profs/admins sont créés par l'admin.
      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showMessage("Compte non configuré. Utilise l'inscription étudiant ou contacte l'admin.");
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      final role = data["role"];
      final profileCompleted = data["profileCompleted"] ?? false;
      final isPaid = data["isPaid"] ?? false;

      if (!mounted) return;

      // 🎯 STUDENT FLOW
      if (role == "student") {
        // STEP 1: PROFILE
        if (!profileCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentRegisterPage(),
            ),
          );
          return;
        }

        // STEP 2: PAYMENT
        if (!isPaid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(),
            ),
          );
          return;
        }
      }

      // 🟢 FINAL DASHBOARD
      final userRole = _roleFromString(role);

      if (userRole == null) {
        _showMessage("Rôle invalide");
        return;
      }

      AppNavigator.openDashboard(context, userRole);

    } on FirebaseAuthException catch (e) {
      String message = "Erreur de connexion";

      if (e.code == "user-not-found") {
        message = "Utilisateur introuvable";
      } else if (e.code == "wrong-password") {
        message = "Mot de passe incorrect";
      } else if (e.code == "invalid-email") {
        message = "Email invalide";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Erreur: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Text(
                "Connexion",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: _emailController,
                label: "Email",
                hintText: "nom@academy.com",
                prefixIcon: Icons.email,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                controller: _passwordController,
                label: "Mot de passe",
                hintText: "••••••••",
                obscureText: true,
                prefixIcon: Icons.lock,
              ),

              const SizedBox(height: 25),

              CustomButton(
                label: _isLoading ? "Connexion..." : "Se connecter",
                onPressed: _isLoading ? null : _login,
                icon: Icons.login,
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(
                          selectedRole: UserRole.student,
                        ),
                      ),
                    );
                  },
                  child: const Text("Créer un compte"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}