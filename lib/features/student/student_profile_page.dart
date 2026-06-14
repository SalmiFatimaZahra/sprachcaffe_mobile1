import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/user_role.dart';
import '../auth/login_page.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // ================= SAFE READ =================
          final prenom = data["prenom"] ?? "";
          final nom = data["nom"] ?? "";
          final email = data["email"] ?? "";
          final telephone = data["telephone"] ?? "";
          final ville = data["ville"] ?? "";
          final adresse = data["adresse"] ?? "";
          final age = data["age"]?.toString() ?? "";
          final sexe = data["sexe"] ?? "";
          final role = data["role"] ?? "student";

          final isPaid = data["isPaid"] ?? false;
          final paymentStatus = data["paymentStatus"] ?? "Non payé";

          // ✅ SAFE COURSES
          final List<Map<String, dynamic>> cours =
          (data["cours"] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade700,
                          Colors.blue.shade400,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Text(
                            prenom.isNotEmpty ? prenom[0] : "E",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "$prenom $nom",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPaid
                                ? "Paiement validé"
                                : "Paiement en attente",
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================= INFO =================
                  sectionTitle("Informations personnelles"),

                  const SizedBox(height: 16),

                  buildCard([
                    profileLine(Icons.person, "Nom", "$prenom $nom"),
                    profileLine(Icons.email, "Email", email),
                    profileLine(Icons.phone, "Téléphone", telephone),
                    profileLine(Icons.cake, "Âge", age),
                    profileLine(Icons.people, "Sexe", sexe),
                    profileLine(Icons.location_city, "Ville", ville),
                    profileLine(Icons.home, "Adresse", adresse),
                    profileLine(Icons.badge, "Rôle", role),
                  ]),

                  const SizedBox(height: 30),

                  // ================= PAYMENT =================
                  sectionTitle("Paiement"),

                  const SizedBox(height: 16),

                  buildCard([
                    profileLine(Icons.payment, "Statut", paymentStatus),
                    profileLine(Icons.check_circle, "Payé",
                        isPaid ? "Oui" : "Non"),
                  ]),

                  const SizedBox(height: 30),

                  // ================= COURSES =================
                  sectionTitle("Mes cours"),

                  const SizedBox(height: 16),

                  if (cours.isEmpty)
                    buildEmptyCourses()
                  else
                    ...cours.map((c) => buildCourseCard(c)),

                  const SizedBox(height: 40),

                  // ================= LOGOUT =================
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(
                              selectedRole: UserRole.student,
                            ),
                          ),
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Déconnexion"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  );

  Widget buildCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(children: children),
  );

  Widget profileLine(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value),
      ],
    ),
  );

  Widget buildCourseCard(Map<String, dynamic> c) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c["langue"] ?? "",
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Niveau: ${c["niveau"] ?? ""}"),
        Text("Mode: ${c["mode"] ?? ""}"),
        Text("Horaire: ${c["horaire"] ?? ""}"),
      ],
    ),
  );

  Widget buildEmptyCourses() => Container(
    padding: const EdgeInsets.all(30),
    child: const Center(
      child: Text("Aucun cours"),
    ),
  );
}