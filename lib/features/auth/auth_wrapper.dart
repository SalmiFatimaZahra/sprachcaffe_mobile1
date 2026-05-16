import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_navigator.dart';
import '../../core/user_role.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

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

  Future<void> _redirectUser(User user) async {
    final roleString = await _authService.getUserRole(user.uid);

    if (!mounted) return;

    if (roleString == null) {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(selectedRole: UserRole.student),
        ),
      );
      return;
    }

    final role = _roleFromString(roleString);

    if (role == null) {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(selectedRole: UserRole.student),
        ),
      );
      return;
    }

    AppNavigator.openDashboard(context, role);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage(selectedRole: UserRole.student);
        }

        Future.microtask(() => _redirectUser(user));

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}