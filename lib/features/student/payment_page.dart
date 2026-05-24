import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_navigator.dart';
import '../../core/user_role.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  // ================= CONTROLLERS =================
  final cardNumberController = TextEditingController();
  final cardNameController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  // ================= STATE =================
  bool isLoading = true;
  bool isPaying = false;

  List<Map<String, dynamic>> selectedCourses = [];
  double total = 0;

  // ================= PRICES =================
  final prices = {
    "Français": 1200,
    "Anglais": 1400,
    "Espagnol": 1100,
    "Allemand": 1500,
    "Arabe": 1000,
    "Italien": 1300,
  };

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // ================= LOAD COURSES =================
  Future<void> loadCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null && data["cours"] is List) {
        selectedCourses = List<Map<String, dynamic>>.from(
          (data["cours"] as List).map(
                (e) => Map<String, dynamic>.from(e),
          ),
        );

        calculateTotal();
      }

    } catch (e) {
      debugPrint("Payment load error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= TOTAL =================
  void calculateTotal() {
    total = selectedCourses.fold(0, (sum, c) {
      final lang = c["langue"];
      return sum + (prices[lang] ?? 1200);
    });

    setState(() {});
  }

  // ================= PAYMENT =================
  Future<void> makePayment() async {

    final card = cardNumberController.text.trim();
    final name = cardNameController.text.trim();
    final expiry = expiryController.text.trim();
    final cvv = cvvController.text.trim();

    if (card.isEmpty || name.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    if (card.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro de carte invalide")),
      );
      return;
    }

    if (cvv.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CVV invalide")),
      );
      return;
    }

    setState(() => isPaying = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      final last4 = card.substring(card.length - 4);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "profileCompleted": true,
        "isPaid": true,
        "paymentStatus": "Payé",
        "payment": {
          "montant": total,
          "date": FieldValue.serverTimestamp(),
          "cardLast4": last4,
          "cardHolder": name,
          "expiry": expiry,
        },
      }, SetOptions(merge: true));

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final role = doc.data()?["role"] ?? "student";

      UserRole userRole = UserRole.student;
      if (role == "teacher") userRole = UserRole.teacher;
      if (role == "admin") userRole = UserRole.admin;

      if (!mounted) return;

      AppNavigator.openDashboard(context, userRole);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur paiement : $e")),
      );
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    cardNameController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Paiement"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ================= SUMMARY =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cours: ${selectedCourses.length}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "${total.toStringAsFixed(0)} DH",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ================= DÉTAIL COURS =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Détail des cours",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...selectedCourses.map((c) {
                    final lang = c["langue"];
                    final price = prices[lang] ?? 1200;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$lang (${c["niveau"]})",
                          ),
                          Text(
                            "$price DH",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= FORM =================
            _field(cardNameController, "Nom sur carte"),
            const SizedBox(height: 12),
            _field(cardNumberController, "Numéro carte",
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _field(expiryController, "MM/YY"),
            const SizedBox(height: 12),
            _field(cvvController, "CVV",
                keyboard: TextInputType.number, obscure: true),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isPaying ? null : makePayment,
                child: isPaying
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text("Payer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FIELD WIDGET =================
  Widget _field(
      TextEditingController controller,
      String label, {
        TextInputType keyboard = TextInputType.text,
        bool obscure = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}