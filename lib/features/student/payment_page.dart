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
  final cardNumberController = TextEditingController();
  final cardNameController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  bool isLoading = false;

  Future<void> makePayment() async {
    if (cardNumberController.text.isEmpty ||
        cardNameController.text.isEmpty ||
        expiryController.text.isEmpty ||
        cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remplir toutes les informations de paiement")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      // 💾 SAVE PAYMENT INFO (optionnel mais utile)
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "isPaid": true,
        "paymentStatus": "paid",

        "payment": {
          "cardLast4": cardNumberController.text
              .trim()
              .substring(cardNumberController.text.length - 4),
          "cardName": cardNameController.text.trim(),
          "expiry": expiryController.text.trim(),
        }
      });

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data() as Map<String, dynamic>;
      final role = data["role"];

      UserRole userRole;

      switch (role) {
        case "student":
          userRole = UserRole.student;
          break;
        case "teacher":
          userRole = UserRole.teacher;
          break;
        default:
          userRole = UserRole.admin;
      }

      if (!mounted) return;

      AppNavigator.openDashboard(context, userRole);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur paiement: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement sécurisé")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Icon(Icons.lock, size: 70, color: Colors.blue),

            const SizedBox(height: 20),

            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Numéro de carte",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: cardNameController,
              decoration: const InputDecoration(
                labelText: "Nom sur la carte",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: "MM/AA",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: cvvController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : makePayment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Payer maintenant"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}