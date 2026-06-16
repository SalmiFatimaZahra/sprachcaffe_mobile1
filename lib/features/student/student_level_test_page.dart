import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/llm_chat_service.dart';
import '../../widgets/premium_header.dart';
import '../../widgets/section_title.dart';

class StudentLevelTestPage extends StatefulWidget {
  final String language;

  const StudentLevelTestPage({
    super.key,
    required this.language,
  });

  @override
  State<StudentLevelTestPage> createState() => _StudentLevelTestPageState();
}

class _StudentLevelTestPageState extends State<StudentLevelTestPage> {
  final LlmChatService _llmService = LlmChatService();

  int current = 0;
  int score = 0;

  int? selectedIndex;
  bool answered = false;
  bool isSaving = false;
  bool isGeneratingTest = true;

  String? generationError;
  String levelSource = 'llm';
  String testSource = 'llm';

  List<Map<String, dynamic>> questions = [];
  final List<Map<String, dynamic>> userAnswers = [];

  @override
  void initState() {
    super.initState();
    generateTestWithLlm();
  }

  String _buildTestGenerationPrompt() {
    return '''
Tu es un professeur expert en évaluation CECR pour un centre de langues.

Objectif : générer un test de niveau dynamique pour la langue suivante : ${widget.language}.

Contraintes obligatoires :
- Génère exactement 10 questions QCM.
- Le test doit couvrir progressivement les niveaux A1, A2, B1, B2 et C1.
- Les questions doivent être adaptées à la langue évaluée : ${widget.language}.
- Chaque question doit avoir exactement 4 choix.
- Il doit y avoir une seule bonne réponse par question.
- Les questions doivent tester grammaire, vocabulaire, compréhension et usage réel.
- Ne mets pas les réponses correctes trop souvent au même index.
- L'explication doit être courte et en français.
- Ne donne aucun texte hors JSON.

Réponds uniquement avec un JSON valide dans ce format exact :
{
  "questions": [
    {
      "question": "Question ici",
      "options": ["choix 1", "choix 2", "choix 3", "choix 4"],
      "correctIndex": 0,
      "explanation": "Explication courte en français",
      "cefrFocus": "A1"
    }
  ]
}
''';
  }

  String _extractJson(String raw) {
    var cleaned = raw.trim();

    cleaned = cleaned
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    final firstObject = cleaned.indexOf('{');
    final lastObject = cleaned.lastIndexOf('}');

    if (firstObject != -1 && lastObject != -1 && lastObject > firstObject) {
      return cleaned.substring(firstObject, lastObject + 1);
    }

    final firstArray = cleaned.indexOf('[');
    final lastArray = cleaned.lastIndexOf(']');

    if (firstArray != -1 && lastArray != -1 && lastArray > firstArray) {
      return cleaned.substring(firstArray, lastArray + 1);
    }

    return cleaned;
  }

  List<Map<String, dynamic>> _parseLlmQuestions(String reply) {
    final decoded = jsonDecode(_extractJson(reply));
    final dynamic rawQuestions = decoded is Map ? decoded['questions'] : decoded;

    if (rawQuestions is! List) {
      throw const FormatException('Le LLM n’a pas retourné une liste de questions.');
    }

    final parsedQuestions = <Map<String, dynamic>>[];

    for (final item in rawQuestions) {
      if (item is! Map) continue;

      final question = (item['question'] ?? '').toString().trim();
      final explanation = (item['explanation'] ?? '').toString().trim();
      final cefrFocus = (item['cefrFocus'] ?? '').toString().trim().toUpperCase();
      final rawOptions = item['options'];
      final rawCorrectIndex = item['correctIndex'] ?? item['correct'];

      if (question.isEmpty || rawOptions is! List || rawOptions.length != 4) {
        continue;
      }

      final options = rawOptions
          .map((option) => option.toString().trim())
          .where((option) => option.isNotEmpty)
          .toList();

      if (options.length != 4) continue;

      final correctIndex = rawCorrectIndex is int
          ? rawCorrectIndex
          : int.tryParse(rawCorrectIndex.toString());

      if (correctIndex == null || correctIndex < 0 || correctIndex > 3) {
        continue;
      }

      parsedQuestions.add({
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation.isEmpty
            ? 'Réponse correcte : ${options[correctIndex]}.'
            : explanation,
        'cefrFocus': RegExp(r'^(A1|A2|B1|B2|C1)$').hasMatch(cefrFocus)
            ? cefrFocus
            : 'NA',
      });
    }

    if (parsedQuestions.length < 6) {
      throw const FormatException('Le test généré est incomplet.');
    }

    return parsedQuestions.take(10).toList();
  }

  Future<void> generateTestWithLlm() async {
    setState(() {
      isGeneratingTest = true;
      generationError = null;
      current = 0;
      score = 0;
      selectedIndex = null;
      answered = false;
      userAnswers.clear();
      questions = [];
    });

    try {
      final reply = await _llmService.sendMessage(
        userMessage: _buildTestGenerationPrompt(),
        history: const <LlmChatMessage>[],
      );

      final generatedQuestions = _parseLlmQuestions(reply);

      if (!mounted) return;

      setState(() {
        questions = generatedQuestions;
        testSource = 'llm';
        isGeneratingTest = false;
      });
    } catch (e) {
      debugPrint('Erreur génération test LLM: $e');

      if (!mounted) return;

      setState(() {
        generationError =
        'Impossible de générer le test avec l’IA. Vérifiez la connexion LLM puis réessayez.';
        isGeneratingTest = false;
      });
    }
  }

  void checkAnswer(int index) {
    if (answered || questions.isEmpty) return;

    final q = questions[current];
    final options = List<String>.from(q['options'] as List);
    final correctIndex = q['correctIndex'] as int;
    final isCorrect = index == correctIndex;

    setState(() {
      selectedIndex = index;
      answered = true;

      userAnswers.add({
        'question': q['question'],
        'options': options,
        'selectedAnswer': options[index],
        'correctAnswer': options[correctIndex],
        'isCorrect': isCorrect,
        'cefrFocus': q['cefrFocus'],
      });

      if (isCorrect) {
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

  String getScoreFallbackLevel() {
    final total = questions.isEmpty ? 10 : questions.length;
    final percentage = score / total;

    if (percentage <= 0.25) return 'A1';
    if (percentage <= 0.45) return 'A2';
    if (percentage <= 0.65) return 'B1';
    if (percentage <= 0.85) return 'B2';
    return 'C1';
  }

  String _buildLlmEvaluationPrompt() {
    final buffer = StringBuffer();

    buffer.writeln(
      'Tu es un évaluateur professionnel CECR pour un centre de langues.',
    );
    buffer.writeln(
      'Le test a été généré par IA. Détermine le niveau réel de l’étudiant à partir des questions, des réponses et de la difficulté CECR de chaque question.',
    );
    buffer.writeln('Langue évaluée : ${widget.language}');
    buffer.writeln('Score brut : $score / ${questions.length}');
    buffer.writeln(
      'Réponds avec un seul niveau parmi : A1, A2, B1, B2, C1. Ne donne aucune phrase, aucun commentaire.',
    );
    buffer.writeln('Réponses de l’étudiant :');

    for (var i = 0; i < userAnswers.length; i++) {
      final answer = userAnswers[i];
      buffer.writeln(
        '${i + 1}. Niveau visé: ${answer['cefrFocus']} | Question: ${answer['question']} | Réponse étudiant: ${answer['selectedAnswer']} | Réponse correcte: ${answer['correctAnswer']} | Correct: ${answer['isCorrect']}',
      );
    }

    return buffer.toString();
  }

  Future<String> determineLevelWithLlm() async {
    final fallbackLevel = getScoreFallbackLevel();

    try {
      final reply = await _llmService.sendMessage(
        userMessage: _buildLlmEvaluationPrompt(),
        history: const <LlmChatMessage>[],
      );

      final normalizedReply = reply.toUpperCase();
      final match = RegExp(r'\b(A1|A2|B1|B2|C1)\b').firstMatch(normalizedReply);

      if (match != null) {
        levelSource = 'llm';
        return match.group(1)!;
      }
    } catch (e) {
      debugPrint('Erreur LLM niveau: $e');
    }

    levelSource = 'score_fallback';
    return fallbackLevel;
  }

  Future<void> saveResult(String level) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final doc = await userRef.get();
    final data = doc.data() ?? {};

    final updatedCourses = (data['cours'] as List? ?? []).map((course) {
      final c = Map<String, dynamic>.from(course as Map);

      if (c['langue'] == widget.language) {
        c['niveau'] = level;
        c['niveauStatus'] = 'determined';
        c['levelDeterminedBy'] = levelSource;
        c['levelDeterminedAt'] = Timestamp.now();
      }

      return c;
    }).toList();

    await userRef.set({
      'language': widget.language,
      'level': level,
      'levelSource': levelSource,
      'testSource': testSource,
      'testGeneratedBy': 'llm',
      'testScore': score,
      'testTotal': questions.length,
      'testLanguage': widget.language,
      'testCompleted': true,
      'levelTestQuestions': questions,
      'levelTestAnswers': userAnswers,
      'cours': updatedCourses,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> showResult() async {
    if (isSaving) return;

    setState(() => isSaving = true);

    final level = await determineLevelWithLlm();

    try {
      await saveResult(level);
    } catch (e) {
      debugPrint('Erreur sauvegarde niveau: $e');
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Résultat du test IA'),
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
              '$score / ${questions.length}',
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
                'Niveau IA : $level',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              levelSource == 'llm'
                  ? 'Questions générées par IA et niveau déterminé par IA.'
                  : 'Questions générées par IA. LLM indisponible pour la note finale : niveau estimé par score.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
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
                'Terminer',
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

  Widget _buildGeneratingState() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          PremiumHeader(
            badge: 'Test généré par IA',
            title: widget.language,
            subtitle: 'L’IA prépare un test personnalisé pour cette langue',
            icon: Icons.auto_awesome_rounded,
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Génération du test par l’IA...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          PremiumHeader(
            badge: 'Test généré par IA',
            title: widget.language,
            subtitle: 'Le test dépend du LLM configuré dans l’application',
            icon: Icons.auto_awesome_rounded,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    generationError ?? 'Erreur de génération du test.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.dark,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: generateTestWithLlm,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Réessayer avec l’IA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGeneratingTest) {
      return _buildGeneratingState();
    }

    if (generationError != null || questions.isEmpty) {
      return _buildGenerationErrorState();
    }

    final q = questions[current];
    final options = List<String>.from(q['options'] as List);
    final correctIndex = q['correctIndex'] as int;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isSaving
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse du niveau par l’IA...'),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            PremiumHeader(
              badge: 'Test de niveau IA',
              title: widget.language,
              subtitle:
              'Questions générées par IA, niveau déterminé par IA',
              icon: Icons.language,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (current + 1) / questions.length,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  SectionTitle('Question ${current + 1}/${questions.length}'),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Text(
                      q['question'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(options.length, (i) {
                    final isCorrect = i == correctIndex;
                    final isSelected = selectedIndex == i;

                    Color bg = Colors.white;

                    if (answered) {
                      if (isCorrect) {
                        bg = Colors.green.shade100;
                      } else if (isSelected) {
                        bg = Colors.red.shade100;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: bg,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          onPressed: answered ? null : () => checkAnswer(i),
                          child: Text(options[i]),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (answered)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        q['explanation'].toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
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
                        child: Text(
                          current == questions.length - 1
                              ? 'Analyser avec l’IA'
                              : 'Suivant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
}
