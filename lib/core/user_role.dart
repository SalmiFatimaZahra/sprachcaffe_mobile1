import 'package:flutter/material.dart';

enum UserRole {
  student,
  teacher,
  admin,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Étudiant';
      case UserRole.teacher:
        return 'Prof';
      case UserRole.admin:
        return 'Administrateur';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.student:
        return 'E';
      case UserRole.teacher:
        return 'P';
      case UserRole.admin:
        return 'A';
    }
  }

  String get description {
    switch (this) {
      case UserRole.student:
        return 'Suivre les cours, consulter le planning, accéder aux ressources et passer le test de niveau.';
      case UserRole.teacher:
        return 'Gérer les groupes, suivre le planning pédagogique et accompagner les étudiants.';
      case UserRole.admin:
        return 'Piloter la plateforme, gérer les utilisateurs, les cours et les indicateurs clés.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.teacher:
        return Icons.co_present_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String get welcomeTitle {
    switch (this) {
      case UserRole.student:
        return 'Mon espace étudiant';
      case UserRole.teacher:
        return 'Tableau de bord enseignant';
      case UserRole.admin:
        return 'Pilotage administrateur';
    }
  }
}
