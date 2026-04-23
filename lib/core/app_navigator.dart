import 'package:flutter/material.dart';

import '../features/admin/admin_shell_page.dart';
import '../features/student/student_shell_page.dart';
import '../features/teacher/teacher_shell_page.dart';
import 'user_role.dart';

class AppNavigator {
  const AppNavigator._();

  static void openDashboard(BuildContext context, UserRole role) {
    late final Widget page;

    switch (role) {
      case UserRole.student:
        page = const StudentShellPage();
        break;
      case UserRole.teacher:
        page = const TeacherShellPage();
        break;
      case UserRole.admin:
        page = const AdminShellPage();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
