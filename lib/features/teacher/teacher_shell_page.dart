import 'package:flutter/material.dart';

import 'teacher_courses_page.dart';
import 'teacher_home_page.dart';
import 'teacher_planning_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_resources_page.dart';
import 'teacher_students_page.dart';

class TeacherShellPage extends StatefulWidget {
  const TeacherShellPage({super.key});

  @override
  State<TeacherShellPage> createState() => _TeacherShellPageState();
}

class _TeacherShellPageState extends State<TeacherShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const TeacherHomePage(),
    const TeacherCoursesPage(),
    const TeacherPlanningPage(),
    const TeacherStudentsPage(),
    const TeacherResourcesPage(),
    const TeacherProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_outlined),
            activeIcon: Icon(Icons.class_rounded),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Étudiants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_outlined),
            activeIcon: Icon(Icons.folder_copy_rounded),
            label: 'Ressources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}