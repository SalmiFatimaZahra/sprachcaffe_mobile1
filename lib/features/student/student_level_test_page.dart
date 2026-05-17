import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentLevelTestPage extends StatefulWidget {
  final String language;

  const StudentLevelTestPage({
    super.key,
    required this.language,
  });

  @override
  State<StudentLevelTestPage> createState() =>
      _StudentLevelTestPageState();
}

class _StudentLevelTestPageState extends State<StudentLevelTestPage> {
  int current = 0;
  int score = 0;

  int? selectedIndex;
  bool answered = false;

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    questions = bank[widget.language] ?? [];

    if (questions.isEmpty) {
      questions = bank["Français"]!;
    }
  }

  void checkAnswer(int index) {
    if (answered) return;

    setState(() {
      selectedIndex = index;
      answered = true;

      if (index == questions[current]["correct"]) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (current < questions.length - 1) {
      setState(() {
        current++;
        selectedIndex = null;
        answered = false;
      });
    } else {
      showResult();
    }
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Résultat final"),
        content: Text(
          "Langue : ${widget.language}\nScore : $score / ${questions.length}",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Terminer"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[current];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            PremiumHeader(
              badge: "Test de niveau",
              title: "Lingolia Style",
              subtitle: widget.language,
              icon: Icons.language,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (current + 1) / questions.length,
                  ),

                  const SizedBox(height: 20),

                  SectionTitle(
                    "Question ${current + 1}/${questions.length}",
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      q["question"],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ...List.generate(q["options"].length, (i) {
                    final isCorrect = i == q["correct"];
                    final isSelected = selectedIndex == i;

                    Color? color;

                    if (answered) {
                      if (isCorrect) {
                        color = Colors.green[100];
                      } else if (isSelected) {
                        color = Colors.red[100];
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color ?? Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.all(16),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => checkAnswer(i),
                          child: Text(q["options"][i]),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  if (answered)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(q["explanation"]),
                    ),

                  const SizedBox(height: 20),

                  if (answered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: nextQuestion,
                        child: const Text(
                          "Suivant",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final Map<String, List<Map<String, dynamic>>> bank = {
    "Français": List.generate(30, (i) {
      return {
        "question": "Question française ${i + 1}",
        "options": ["A", "B", "C", "D"],
        "correct": i % 4,
        "explanation": "Explication ${i + 1}",
      };
    }),

    "Anglais": List.generate(30, (i) {
      return {
        "question": "English question ${i + 1}",
        "options": ["A", "B", "C", "D"],
        "correct": i % 4,
        "explanation": "Explanation ${i + 1}",
      };
    }),

    "Espagnol": List.generate(30, (i) {
      return {
        "question": "Pregunta ${i + 1}",
        "options": ["A", "B", "C", "D"],
        "correct": i % 4,
        "explanation": "Explicación ${i + 1}",
      };
    }),
  };
}