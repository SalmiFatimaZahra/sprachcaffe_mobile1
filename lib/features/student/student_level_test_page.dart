import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _StudentLevelTestPageState
    extends State<StudentLevelTestPage> {
  int current = 0;
  int score = 0;

  int? selectedIndex;
  bool answered = false;
  bool isSaving = false;

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();

    questions = bank[widget.language] ?? bank["Français"]!;
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

  String getLevel() {
    if (score <= 2) return "A1";
    if (score <= 4) return "A2";
    if (score <= 6) return "B1";
    if (score <= 8) return "B2";
    return "C1";
  }

  Future<void> saveResult(String level) async {
    try {
      setState(() => isSaving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "level": level,
        "testScore": score,
        "testLanguage": widget.language,
        "testCompleted": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> showResult() async {
    final level = getLevel();

    await saveResult(level);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Résultat du test"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.language,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "$score / ${questions.length}",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Niveau : $level",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                "Terminer",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[current];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isSaving
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            PremiumHeader(
              badge: "Test de niveau",
              title: widget.language,
              subtitle:
              "Répondez aux questions pour connaître votre niveau",
              icon: Icons.language,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value:
                    (current + 1) / questions.length,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 20),

                  SectionTitle(
                    "Question ${current + 1}/${questions.length}",
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                      ),
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

                  ...List.generate(
                    q["options"].length,
                        (i) {
                      final isCorrect =
                          i == q["correct"];

                      final isSelected =
                          selectedIndex == i;

                      Color bg = Colors.white;

                      if (answered) {
                        if (isCorrect) {
                          bg = Colors.green.shade100;
                        } else if (isSelected) {
                          bg = Colors.red.shade100;
                        }
                      }

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style:
                            ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: bg,
                              foregroundColor:
                              Colors.black,
                              padding:
                              const EdgeInsets.all(
                                  16),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(14),
                                side:
                                const BorderSide(
                                  color:
                                  AppColors.border,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                checkAnswer(i),
                            child: Text(
                              q["options"][i],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  if (answered)
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius:
                        BorderRadius.circular(
                            14),
                      ),
                      child: Text(
                        q["explanation"],
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (answered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.primary,
                          padding:
                          const EdgeInsets.all(
                              16),
                        ),
                        onPressed: nextQuestion,
                        child: const Text(
                          "Suivant",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
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
    "Français": [
      {
        "question":
        "Ce soir, nous ___ au restaurant.",
        "options": [
          "allons",
          "allez",
          "vais",
          "va"
        ],
        "correct": 0,
        "explanation":
        "Avec « nous », le verbe devient « allons ».",
      },
      {
        "question":
        "Je ___ étudiant.",
        "options": [
          "suis",
          "es",
          "est",
          "sommes"
        ],
        "correct": 0,
        "explanation":
        "Avec « je », on utilise « suis ».",
      },
      {
        "question":
        "Hier, ils ___ un film.",
        "options": [
          "regardent",
          "ont regardé",
          "regarder",
          "regarde"
        ],
        "correct": 1,
        "explanation":
        "Le passé composé correct est « ont regardé ».",
      },
      {
        "question":
        "Il faut que tu ___ tes devoirs.",
        "options": [
          "finis",
          "finisses",
          "finir",
          "finissait"
        ],
        "correct": 1,
        "explanation":
        "Après « il faut que », on utilise le subjonctif.",
      },
      {
        "question":
        "Elle est ___ intelligente que lui.",
        "options": [
          "plus",
          "très",
          "moins",
          "beaucoup"
        ],
        "correct": 0,
        "explanation":
        "Comparatif : « plus intelligente ».",
      },
      {
        "question":
        "Je cherche quelqu’un qui ___ chinois.",
        "options": [
          "parle",
          "parles",
          "parler",
          "parlons"
        ],
        "correct": 0,
        "explanation":
        "Sujet singulier → parle.",
      },
      {
        "question":
        "Quand j’étais petit, je ___ au foot.",
        "options": [
          "jouais",
          "joue",
          "joué",
          "jouer"
        ],
        "correct": 0,
        "explanation":
        "L’imparfait exprime une habitude.",
      },
      {
        "question":
        "Tu peux me dire ___ tu habites ?",
        "options": [
          "qui",
          "où",
          "que",
          "quoi"
        ],
        "correct": 1,
        "explanation":
        "« où » indique le lieu.",
      },
      {
        "question":
        "Bien qu’il ___ malade, il travaille.",
        "options": [
          "est",
          "sera",
          "soit",
          "était"
        ],
        "correct": 2,
        "explanation":
        "« Bien que » demande le subjonctif.",
      },
      {
        "question":
        "Nous ___ partir maintenant.",
        "options": [
          "devons",
          "devait",
          "devez",
          "doit"
        ],
        "correct": 0,
        "explanation":
        "Avec « nous », on utilise « devons ».",
      },
    ],

    "Anglais": [
      {
        "question":
        "She ___ to school every day.",
        "options": [
          "go",
          "goes",
          "going",
          "gone"
        ],
        "correct": 1,
        "explanation":
        "Third person singular → goes.",
      },
      {
        "question":
        "I ___ football yesterday.",
        "options": [
          "play",
          "played",
          "playing",
          "plays"
        ],
        "correct": 1,
        "explanation":
        "Yesterday → simple past.",
      },
      {
        "question":
        "If I had money, I ___ travel.",
        "options": [
          "will",
          "would",
          "am",
          "can"
        ],
        "correct": 1,
        "explanation":
        "Second conditional uses would.",
      },
      {
        "question":
        "They ___ dinner when I arrived.",
        "options": [
          "have",
          "were having",
          "had",
          "having"
        ],
        "correct": 1,
        "explanation":
        "Past continuous action.",
      },
      {
        "question":
        "This is the man ___ helped me.",
        "options": [
          "which",
          "who",
          "where",
          "whose"
        ],
        "correct": 1,
        "explanation":
        "Use « who » for people.",
      },
      {
        "question":
        "I’ve lived here ___ 2018.",
        "options": [
          "since",
          "for",
          "during",
          "from"
        ],
        "correct": 0,
        "explanation":
        "Use since with a starting point.",
      },
      {
        "question":
        "You ___ smoke here.",
        "options": [
          "mustn’t",
          "can",
          "should",
          "may"
        ],
        "correct": 0,
        "explanation":
        "Mustn’t expresses prohibition.",
      },
      {
        "question":
        "He has ___ finished his work.",
        "options": [
          "already",
          "tomorrow",
          "last",
          "yesterday"
        ],
        "correct": 0,
        "explanation":
        "Already fits present perfect.",
      },
      {
        "question":
        "We ___ dinner now.",
        "options": [
          "eat",
          "eats",
          "are eating",
          "ate"
        ],
        "correct": 2,
        "explanation":
        "Now → present continuous.",
      },
      {
        "question":
        "She is ___ than her sister.",
        "options": [
          "tall",
          "taller",
          "tallest",
          "more tall"
        ],
        "correct": 1,
        "explanation":
        "Comparative adjective → taller.",
      },
    ],

    "Espagnol": [
      {
        "question":
        "Yo ___ estudiante.",
        "options": [
          "soy",
          "eres",
          "es",
          "somos"
        ],
        "correct": 0,
        "explanation":
        "Con yo → soy.",
      },
      {
        "question":
        "Nosotros ___ al cine ayer.",
        "options": [
          "vamos",
          "fuimos",
          "iremos",
          "iba"
        ],
        "correct": 1,
        "explanation":
        "Ayer → pasado.",
      },
      {
        "question":
        "Ella ___ café cada mañana.",
        "options": [
          "bebo",
          "bebe",
          "bebes",
          "bebemos"
        ],
        "correct": 1,
        "explanation":
        "Con ella → bebe.",
      },
      {
        "question":
        "Si tuviera dinero, ___ viajar.",
        "options": [
          "voy",
          "iría",
          "fui",
          "iba"
        ],
        "correct": 1,
        "explanation":
        "Condicional correcto.",
      },
      {
        "question":
        "¿Dónde ___ ayer?",
        "options": [
          "estás",
          "estuviste",
          "estar",
          "estés"
        ],
        "correct": 1,
        "explanation":
        "Pregunta en pasado.",
      },
      {
        "question":
        "Nosotros ___ español.",
        "options": [
          "hablo",
          "hablas",
          "hablamos",
          "habla"
        ],
        "correct": 2,
        "explanation":
        "Con nosotros → hablamos.",
      },
      {
        "question":
        "Ellos ___ en Madrid.",
        "options": [
          "vive",
          "viven",
          "vivo",
          "vivimos"
        ],
        "correct": 1,
        "explanation":
        "Ellos → viven.",
      },
      {
        "question":
        "Yo ___ una pizza.",
        "options": [
          "quiero",
          "quieres",
          "quiere",
          "queremos"
        ],
        "correct": 0,
        "explanation":
        "Con yo → quiero.",
      },
      {
        "question":
        "Mañana ___ a la playa.",
        "options": [
          "voy",
          "iremos",
          "fui",
          "iba"
        ],
        "correct": 1,
        "explanation":
        "Mañana → futur.",
      },
      {
        "question":
        "¿Qué hora ___?",
        "options": [
          "son",
          "es",
          "soy",
          "somos"
        ],
        "correct": 0,
        "explanation":
        "On dit « Qué hora son ».",
      },
    ],
  };
}