import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/user_role.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../student/student_register_page.dart';
import '../student/payment_page.dart';
import '../../core/app_navigator.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  UserRole _roleFromString(String role) {
    switch (role) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      default:
        return UserRole.admin;
    }
  }

  Future<void> _handleUser(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      await FirebaseAuth.instance.signOut();
      return;
    }

    final data = doc.data()!;

    final role = _roleFromString(data["role"]);
    final profileCompleted = data["profileCompleted"] ?? false;
    final isPaid = data["isPaid"] ?? false;

    if (!mounted) return;

    // 🟡 STUDENT FLOW
    if (role == UserRole.student) {
      if (!profileCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentRegisterPage()),
        );
        return;
      }

      if (!isPaid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentPage()),
        );
        return;
      }
    }

    // 🟢 FINAL DASHBOARD
    AppNavigator.openDashboard(context, role);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage(selectedRole: UserRole.student);
        }

        Future.microtask(() => _handleUser(user));

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}