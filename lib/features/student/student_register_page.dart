import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../student/payment_page.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() =>
      _StudentRegisterPageState();
}

class _StudentRegisterPageState
    extends State<StudentRegisterPage> {

  // ================= CONTROLLERS =================

  final prenomController = TextEditingController();
  final nomController = TextEditingController();
  final telephoneController = TextEditingController();
  final emailController = TextEditingController();
  final adresseController = TextEditingController();
  final villeController = TextEditingController();
  final ageController = TextEditingController();

  // ================= LISTES =================

  final List<String> langues = [
    "Français",
    "Anglais",
    "Espagnol",
    "Allemand",
    "Arabe",
    "Italien",
  ];

  final List<String> niveaux = [
    "Débutant",
    "A1",
    "A2",
    "B1",
    "B2",
    "C1",
  ];

  final List<String> horaires = [
    "Matin",
    "Après-midi",
    "Soir",
    "Week-end",
  ];

  // ================= DONNÉES =================

  String sexe = "Femme";
  bool isLoading = false;

  // ================= COURS =================

  List<Map<String, dynamic>> selectedCourses = [];

  // ================= AJOUTER COURS =================

  void ajouterCours() {

    setState(() {

      selectedCourses.add({
        "langue": "Français",
        "niveau": "Débutant",
        "mode": "Présentiel",
        "horaire": "Matin",
      });
    });
  }

  // ================= ENREGISTRER =================

  Future<void> enregistrerInscription() async {

    if (prenomController.text.isEmpty ||
        nomController.text.isEmpty ||
        telephoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        adresseController.text.isEmpty ||
        villeController.text.isEmpty ||
        ageController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
        ),
      );

      return;
    }

    if (selectedCourses.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoutez au moins un cours"),
        ),
      );

      return;
    }

    setState(() => isLoading = true);

    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({

        "prenom": prenomController.text.trim(),
        "nom": nomController.text.trim(),
        "telephone": telephoneController.text.trim(),
        "email": emailController.text.trim(),
        "adresse": adresseController.text.trim(),
        "ville": villeController.text.trim(),
        "age": ageController.text.trim(),
        "sexe": sexe,

        "cours": selectedCourses
            .map((c) => Map<String, dynamic>.from(c))
            .toList(),

        "profileCompleted": true,
        "isPaid": false,
        "paymentStatus": "Pending",
        "role": "student",
        "dateInscription": FieldValue.serverTimestamp(),

      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentPage(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message = "Erreur d'authentification";

      switch (e.code) {
        case "email-already-in-use":
          message = "Cet email est déjà utilisé";
          break;
        case "invalid-email":
          message = "Email invalide";
          break;
        case "weak-password":
          message = "Mot de passe trop faible";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // ================= DISPOSE =================

  @override
  void dispose() {

    prenomController.dispose();
    nomController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    adresseController.dispose();
    villeController.dispose();
    ageController.dispose();

    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Inscription",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: ajouterCours,
        icon: const Icon(Icons.add),
        label: const Text("Ajouter un cours"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= HEADER =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ],
                ),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 42,
                  ),

                  SizedBox(height: 18),

                  Text(
                    "Centre de Langues",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Complétez votre inscription et choisissez vos cours.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= INFOS =================

            const Text(
              "Informations personnelles",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: buildField(
                    controller: prenomController,
                    label: "Prénom",
                    icon: Icons.person,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildField(
                    controller: nomController,
                    label: "Nom",
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            buildField(
              controller: emailController,
              label: "Adresse email",
              icon: Icons.email,
              keyboard: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            buildField(
              controller: telephoneController,
              label: "Téléphone",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Expanded(
                  child: buildField(
                    controller: ageController,
                    label: "Âge",
                    icon: Icons.cake,
                    keyboard: TextInputType.number,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField(
                    value: sexe,
                    decoration:
                    inputDecoration(
                      "Sexe",
                      Icons.people,
                    ),

                    items: const [

                      DropdownMenuItem(
                        value: "Homme",
                        child: Text("Homme"),
                      ),

                      DropdownMenuItem(
                        value: "Femme",
                        child: Text("Femme"),
                      ),
                    ],

                    onChanged: (value) {

                      setState(() {
                        sexe = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            buildField(
              controller: villeController,
              label: "Ville",
              icon: Icons.location_city,
            ),

            const SizedBox(height: 16),

            buildField(
              controller: adresseController,
              label: "Adresse",
              icon: Icons.home,
            ),

            const SizedBox(height: 30),

            // ================= COURS =================

            const Text(
              "Cours sélectionnés",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (selectedCourses.isEmpty)

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: const Column(
                  children: [

                    Icon(
                      Icons.menu_book,
                      size: 40,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 10),

                    Text("Aucun cours ajouté"),
                  ],
                ),
              ),

            ...List.generate(selectedCourses.length, (index) {

              final Map<String, dynamic> cours =
              selectedCourses[index];

              cours["mode"] ??= "Présentiel";

              return Container(

                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: Column(
                  children: [

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [

                        Text(
                          "Cours ${index + 1}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          onPressed: () {

                            setState(() {
                              selectedCourses.removeAt(index);
                            });
                          },

                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField(
                      value: cours["langue"],

                      decoration: inputDecoration(
                        "Langue",
                        Icons.language,
                      ),

                      items: langues.map((langue) {

                        return DropdownMenuItem(
                          value: langue,
                          child: Text(langue),
                        );

                      }).toList(),

                      onChanged: (value) {

                        setState(() {
                          cours["langue"] = value as String;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField(
                      value: cours["niveau"],

                      decoration: inputDecoration(
                        "Niveau",
                        Icons.school,
                      ),

                      items: niveaux.map((niveau) {

                        return DropdownMenuItem(
                          value: niveau,
                          child: Text(niveau),
                        );

                      }).toList(),

                      onChanged: (value) {

                        setState(() {
                          cours["niveau"] = value as String;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField(
                      value: cours["horaire"],

                      decoration: inputDecoration(
                        "Horaire",
                        Icons.schedule,
                      ),

                      items: horaires.map((horaire) {

                        return DropdownMenuItem(
                          value: horaire,
                          child: Text(horaire),
                        );

                      }).toList(),

                      onChanged: (value) {

                        setState(() {
                          cours["horaire"] = value as String;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [

                        Expanded(
                          child: GestureDetector(

                            onTap: () {

                              setState(() {
                                cours["mode"] =
                                "Présentiel";
                              });
                            },

                            child: Container(

                              padding:
                              const EdgeInsets.all(16),

                              decoration: BoxDecoration(

                                color:
                                cours["mode"] ==
                                    "Présentiel"
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade100,

                                borderRadius:
                                BorderRadius.circular(16),

                                border: Border.all(
                                  color:
                                  cours["mode"] ==
                                      "Présentiel"
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),

                              child: const Column(
                                children: [

                                  Icon(Icons.school),

                                  SizedBox(height: 10),

                                  Text("Présentiel"),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: GestureDetector(

                            onTap: () {

                              setState(() {
                                cours["mode"] =
                                "En ligne";
                              });
                            },

                            child: Container(

                              padding:
                              const EdgeInsets.all(16),

                              decoration: BoxDecoration(

                                color:
                                cours["mode"] ==
                                    "En ligne"
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade100,

                                borderRadius:
                                BorderRadius.circular(16),

                                border: Border.all(
                                  color:
                                  cours["mode"] ==
                                      "En ligne"
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),

                              child: const Column(
                                children: [

                                  Icon(Icons.laptop_mac),

                                  SizedBox(height: 10),

                                  Text("En ligne"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),

            // ================= BUTTON =================

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),

                onPressed:
                isLoading
                    ? null
                    : enregistrerInscription,

                child: isLoading

                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )

                    : const Text(
                  "Continuer vers le paiement",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {

    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: inputDecoration(label, icon),
    );
  }

  InputDecoration inputDecoration(
      String label,
      IconData icon,
      ) {

    return InputDecoration(

      labelText: label,

      prefixIcon: Icon(icon),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),

        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),

        borderSide: BorderSide(
          color: Colors.blue.shade700,
          width: 2,
        ),
      ),
    );
  }
}