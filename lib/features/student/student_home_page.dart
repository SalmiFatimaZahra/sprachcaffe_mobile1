import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/user_role.dart';
import '../auth/login_page.dart';
import '../../widgets/course_card.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentHomePage extends StatelessWidget {
  final VoidCallback onOpenLevelTest;
  final VoidCallback onOpenChatbot;
  final void Function([String courseTitle]) onOpenCourseDetails;

  const StudentHomePage({
    super.key,
    required this.onOpenLevelTest,
    required this.onOpenChatbot,
    required this.onOpenCourseDetails,
  });

  // ================= LOGOUT =================
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(
          selectedRole: UserRole.student,
        ),
      ),
          (route) => false,
    );
  }

  // ================= ADD COURSE BOTTOM SHEET =================
  void _showAddCourseSheet(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String langue = "Français";
    String horaire = "Matin";
    String mode = "Présentiel";

    final langues = ["Français", "Anglais", "Espagnol", "Allemand", "Arabe", "Italien"];
    final horaires = ["Matin", "Après-midi", "Soir", "Week-end"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Ajouter un cours",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField(
                      value: langue,
                      decoration: _input("Langue", Icons.language),
                      items: langues.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setStateSheet(() => langue = v.toString()),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.psychology_alt, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Niveau : à déterminer par l’IA après le test",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField(
                      value: horaire,
                      decoration: _input("Horaire", Icons.schedule),
                      items: horaires.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setStateSheet(() => horaire = v.toString()),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setStateSheet(() => mode = "Présentiel"),
                            child: _modeBox("Présentiel", Icons.school, mode == "Présentiel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setStateSheet(() => mode = "En ligne"),
                            child: _modeBox("En ligne", Icons.laptop_mac, mode == "En ligne"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          final userRef = FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid);

                          final userDoc = await userRef.get();
                          final userData = userDoc.data() ?? {};
                          final bool alreadyTested = userData["testCompleted"] == true;
                          final String savedLevel =
                          (userData["level"] ?? "À déterminer après test").toString();

                          final newCourse = {
                            "langue": langue,
                            "niveau": alreadyTested ? savedLevel : "À déterminer après test",
                            "niveauStatus": alreadyTested ? "determined" : "pending_test",
                            "horaire": horaire,
                            "mode": mode,
                          };

                          await userRef.set({
                            "language": langue,
                            if (!alreadyTested) "level": "À déterminer",
                            if (!alreadyTested) "testCompleted": false,
                            "cours": FieldValue.arrayUnion([newCourse]),
                          }, SetOptions(merge: true));

                          Navigator.pop(context);
                        },
                        child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================
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

        final selectedCourses = List<Map<String, dynamic>>.from(
          (data["cours"] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );

        final fullName = "${data["prenom"] ?? ""} ${data["nom"] ?? ""}".trim();

        final isPaid = data["isPaid"] ?? false;
        final bool testCompleted = data["testCompleted"] == true;

        final coursesCount = selectedCourses.length;

        final String level = (data["level"] ??
            (selectedCourses.isNotEmpty
                ? selectedCourses.first["niveau"]
                : "À déterminer"))
            .toString();

        final attendance = data["attendance"] ?? 0;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [

                // ================= HEADER =================
                PremiumHeader(
                  badge: isPaid ? "Étudiant Premium" : "Paiement en attente",
                  title: "Bonjour $fullName 👋",
                  subtitle: "Ton espace d'apprentissage",
                  icon: Icons.school_rounded,
                  bottom: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _HeaderMiniStat(value: level, label: "Niveau")),
                          const SizedBox(width: 12),
                          Expanded(child: _HeaderMiniStat(value: "$coursesCount", label: "Cours")),
                          const SizedBox(width: 12),
                          Expanded(child: _HeaderMiniStat(value: "$attendance%", label: "Assiduité")),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text("Déconnexion"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= TEST DE NIVEAU =================
                // Le bouton du test s'affiche seulement si l'étudiant
                // n'a pas encore passé le test.
                if (!testCompleted) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: onOpenLevelTest,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.dark],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.quiz_rounded, color: Colors.white, size: 32),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Test de niveau\nÉvalue ton niveau automatiquement",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (testCompleted) const SizedBox(height: 8),

                // ================= ACTIONS =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle("Actions rapides"),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [

                      // ✅ UNIQUE bouton ajouter cours
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCourseSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter un cours"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.smart_toy_rounded,
                              title: "Chatbot",
                              subtitle: "IA",
                              onTap: onOpenChatbot,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.menu_book_rounded,
                              title: "Cours",
                              subtitle: "Mes formations",
                              onTap: () => onOpenCourseDetails(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ================= COURS =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle("Mes cours"),
                ),

                const SizedBox(height: 14),

                if (selectedCourses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Aucun cours"),
                  ),

                ...selectedCourses.map((cours) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CourseCard(
                    title: cours["langue"] ?? "",
                    subtitle: "${cours["niveau"] ?? "À déterminer"} • ${cours["mode"]}",
                    badge: isPaid ? "Actif" : "En attente",
                    schedule: cours["horaire"] ?? "",
                    icon: Icons.school,
                    onTap: () => onOpenCourseDetails(cours["langue"]),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeBox(String text, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
      ),
      child: Column(
        children: [Icon(icon), const SizedBox(height: 8), Text(text)],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

// ================= MINI STAT =================
class _HeaderMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderMiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
      ],
    );
  }
}

// ================= QUICK CARD =================
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}