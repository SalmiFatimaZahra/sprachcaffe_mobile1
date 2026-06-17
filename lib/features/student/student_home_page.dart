import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../student/payment_page.dart';
import '../student/student_level_test_page.dart';
import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentHomePage extends StatelessWidget {
  final VoidCallback onOpenLevelTest;
  final VoidCallback onOpenChatbot;
  final void Function(String courseId) onOpenCourseDetails;

  const StudentHomePage({
    super.key,
    required this.onOpenLevelTest,
    required this.onOpenChatbot,
    required this.onOpenCourseDetails,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(selectedRole: UserRole.student),
      ),
          (route) => false,
    );
  }

  void _showAddCourseSheet(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String langue = "Français";
    String horaire = "Matin";
    String mode = "Présentiel";

    final langues = ["Français", "Anglais", "Espagnol", "Allemand", "Arabe", "Italien"];
    final horaires = ["En cours de la semaine", "Week-end"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ajouter un cours",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField(
                    value: langue,
                    decoration: _input("Langue", Icons.language),
                    items: langues
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => langue = v.toString()),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField(
                    value: horaire,
                    decoration: _input("Horaire", Icons.schedule),
                    items: horaires
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => horaire = v.toString()),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _modeBox("Présentiel", mode == "Présentiel", () {
                          setState(() => mode = "Présentiel");
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _modeBox("En ligne", mode == "En ligne", () {
                          setState(() => mode = "En ligne");
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final userRef =
                        FirebaseFirestore.instance.collection("users").doc(uid);

                        final courseId =
                            FirebaseFirestore.instance.collection("courses").doc().id;

                        final newCourse = {
                          "courseId": courseId,
                          "langue": langue,
                          "niveau": "",
                          "horaire": horaire,
                          "mode": mode,
                          "paid": false,
                          "testCompleted": false,
                          "testScore": 0,
                        };

                        await userRef.set({
                          "cours": FieldValue.arrayUnion([newCourse]),
                          "isPaid": false,
                          "paymentStatus": "Pending",
                        }, SetOptions(merge: true));

                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentPage(),
                          ),
                        );
                      },
                      child: const Text("Ajouter"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final courses = List<Map<String, dynamic>>.from(
          (data["cours"] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );

        final fullName =
        "${data["prenom"] ?? ""} ${data["nom"] ?? ""}".trim();

        final isPaid = data["isPaid"] ?? false;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                PremiumHeader(
                  badge: isPaid ? "Premium" : "Paiement requis",
                  title: "Bonjour $fullName 👋",
                  subtitle: "Ton espace d'apprentissage",
                  icon: Icons.school,
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCourseSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un cours"),
                  ),
                ),

                const SizedBox(height: 20),

                const SectionTitle("Mes cours"),

                const SizedBox(height: 10),

                if (courses.isEmpty)
                  const Text("Aucun cours"),

                ...courses.map((cours) {
                  final bool paid = cours["paid"] == true;
                  final bool testCompleted = cours["testCompleted"] == true;
                  final String courseId = cours["courseId"] ?? "";
                  final String langue = cours["langue"] ?? "Français";

                  String badge;
                  IconData icon;

                  if (!paid) {
                    badge = "Paiement requis";
                    icon = Icons.payment;
                  } else if (!testCompleted) {
                    badge = "Faire le test";
                    icon = Icons.quiz;
                  } else {
                    badge = "Actif";
                    icon = Icons.school;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: CourseCard(
                      title: langue,
                      subtitle: testCompleted
                          ? "${cours["niveau"]} • ${cours["mode"]}"
                          : "Niveau à déterminer • ${cours["mode"]}",
                      badge: badge,
                      schedule: cours["horaire"] ?? "",
                      icon: icon,
                      onTap: () {
                        if (!paid) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentPage(),
                            ),
                          );
                          return;
                        }

                        if (!testCompleted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentLevelTestPage(
                                language: langue, // ✅ IMPORTANT FIX ICI
                              ),
                            ),
                          );
                          return;
                        }

                        onOpenCourseDetails(courseId);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _modeBox(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: Text(text)),
      ),
    );
  }
}