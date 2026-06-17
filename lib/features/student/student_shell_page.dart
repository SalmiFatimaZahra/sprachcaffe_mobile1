import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'student_chatbot_page.dart';
import 'student_course_details_page.dart';
import 'student_courses_page.dart';
import 'student_home_page.dart';
import 'student_level_test_page.dart';
import 'student_planning_page.dart';
import 'student_profile_page.dart';
import 'student_resources_page.dart';

class StudentShellPage extends StatefulWidget {
  const StudentShellPage({super.key});

  @override
  State<StudentShellPage> createState() => _StudentShellPageState();
}

class _StudentShellPageState extends State<StudentShellPage> {
  int _currentIndex = 0;

  String language = "Français";
  bool isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    loadUserLanguage();
  }

  Future<void> loadUserLanguage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final data = doc.data();

      if (data != null) {
        String resolvedLanguage = (data["language"] ?? "").toString();

        if (resolvedLanguage.isEmpty && data["cours"] is List) {
          final courses = data["cours"] as List;

          if (courses.isNotEmpty && courses.first is Map) {
            final firstCourse =
            Map<String, dynamic>.from(courses.first as Map);

            resolvedLanguage =
                (firstCourse["langue"] ?? "").toString();
          }
        }

        setState(() {
          language = resolvedLanguage.isEmpty ? "Français" : resolvedLanguage;
          isLoadingLanguage = false;
        });
      } else {
        setState(() => isLoadingLanguage = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoadingLanguage = false);
    }
  }

  // ✅ CORRECT: courseId obligatoire
  void _openCourseDetails(String courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentCourseDetailsPage(courseId: courseId),
      ),
    );
  }

  Future<void> _openLevelTest() async {
    if (isLoadingLanguage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chargement de la langue...")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final data = doc.data() ?? {};

    if (data["testCompleted"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le test de niveau est déjà passé.")),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentLevelTestPage(language: language),
      ),
    );
  }

  void _openChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudentChatbotPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return StudentHomePage(
          onOpenCourseDetails: (String courseId) {
            _openCourseDetails(courseId);
          },
          onOpenLevelTest: _openLevelTest,
          onOpenChatbot: _openChatbot,
        );

      case 1:
        return StudentCoursesPage(
          onOpenCourseDetails: (String courseId) {
            _openCourseDetails(courseId);
          },
        );

      case 2:
        return const StudentPlanningPage();

      case 3:
        return const StudentResourcesPage();

      case 4:
        return const StudentProfilePage();

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatbot,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text(
          'Chatbot',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Ressources',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}