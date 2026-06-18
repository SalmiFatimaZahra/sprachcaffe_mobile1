import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmChatMessage {
  const LlmChatMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class LlmChatService {
  LlmChatService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Android Emulator : la machine Windows est accessible avec 10.0.2.2.
  static const String _llmEndpoint = 'http://10.0.2.2:11434/api/chat';

  // Pour Chrome Web, remplace par :
  // static const String _llmEndpoint = 'http://localhost:11434/api/chat';

  static const String _ollamaModel = 'llama3.2';

  static const Map<String, dynamic> _placementTestJsonSchema = {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'questions': {
        'type': 'array',
        'minItems': 10,
        'maxItems': 10,
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'question': {
              'type': 'string',
            },
            'options': {
              'type': 'array',
              'minItems': 4,
              'maxItems': 4,
              'items': {
                'type': 'string',
              },
            },
            'correctIndex': {
              'type': 'integer',
              'minimum': 0,
              'maximum': 3,
            },
            'explanation': {
              'type': 'string',
            },
            'cefrFocus': {
              'type': 'string',
              'enum': ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
            },
          },
          'required': [
            'question',
            'options',
            'correctIndex',
            'explanation',
            'cefrFocus',
          ],
        },
      },
    },
    'required': ['questions'],
  };

  Future<String> sendMessage({
    required String userMessage,
    required List<LlmChatMessage> history,
  }) async {
    final cleanMessage = userMessage.trim();

    if (cleanMessage.isEmpty) {
      return 'Écris une question pour que je puisse t’aider.';
    }

    final context = await _loadStudentContext();

    // Les questions du profil restent locales pour afficher seulement les infos profil.
    if (_isProfileQuestion(cleanMessage)) {
      return _profileOnlyReply(context);
    }

    final isPlacementTestRequest =
    _isPlacementTestGenerationRequest(cleanMessage);

    try {
      return await _callOllama(
        userMessage: cleanMessage,
        history: history,
        context: context,
        structuredPlacementTest: isPlacementTestRequest,
      );
    } catch (e) {
      debugPrint('Ollama error: $e');

      // Ne renvoie jamais un texte local à la place du JSON attendu par
      // l'écran du test, sinon jsonDecode échouera de nouveau.
      if (isPlacementTestRequest) {
        throw Exception(
          'Impossible de générer un test valide avec Ollama. $e',
        );
      }

      return '${_localAssistantReply(cleanMessage, context)}\n\n'
          'Note : Ollama n’est pas disponible pour le moment. '
          'J’ai utilisé la réponse locale de secours.';
    }
  }

  Future<Map<String, dynamic>> _loadStudentContext() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {
        'isLoggedIn': false,
      };
    }

    final context = <String, dynamic>{
      'isLoggedIn': true,
      'uid': user.uid,
      'email': user.email,
    };

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();

      if (data != null) {
        context.addAll({
          'name': _bestName(data),
          'role': data['role'],
          'language': data['language'] ?? data['langue'],
          'level': data['level'] ?? data['niveau'],
          'profileCompleted': data['profileCompleted'],
          'isPaid': data['isPaid'],
          'paymentStatus': data['paymentStatus'],
          'selectedCourses': data['cours'] ?? [],
        });
      }
    } catch (e) {
      debugPrint('Student context user error: $e');
    }

    try {
      final email = user.email?.trim().toLowerCase();

      if (email != null && email.isNotEmpty) {
        final studentCourses = await _firestore
            .collection('teacher_students')
            .where('studentEmail', isEqualTo: email)
            .limit(10)
            .get();

        context['assignedCourses'] = studentCourses.docs.map((doc) {
          final data = doc.data();

          return {
            'courseTitle': data['courseTitle'],
            'courseId': data['courseId'],
            'teacherEmail': data['teacherEmail'],
            'teacherId': data['teacherId'],
            'level': data['level'],
            'createdAt': data['createdAt']?.toString(),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Student context courses error: $e');
    }

    try {
      final sessions = await _firestore.collection('sessions').limit(8).get();

      context['upcomingSessions'] = sessions.docs.map((doc) {
        final data = doc.data();

        return {
          'courseTitle': data['courseTitle'],
          'date': data['date'],
          'time': data['time'],
          'room': data['room'],
          'groupName': data['groupName'],
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Student context sessions error: $e');
    }

    return context;
  }

  String _bestName(Map<String, dynamic> data) {
    final name = data['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final prenom = data['prenom']?.toString().trim() ?? '';
    final nom = data['nom']?.toString().trim() ?? '';
    final fullName = '$prenom $nom'.trim();

    return fullName.isEmpty ? 'étudiant' : fullName;
  }

  Future<String> _callOllama({
    required String userMessage,
    required List<LlmChatMessage> history,
    required Map<String, dynamic> context,
    required bool structuredPlacementTest,
  }) async {
    final systemPrompt = structuredPlacementTest
        ? _buildPlacementTestSystemPrompt(context)
        : _buildSystemPrompt(context);

    // Pour un test, on évite d'envoyer l'historique du chatbot afin de ne pas
    // perturber le format JSON attendu.
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      if (!structuredPlacementTest)
        ...history.map((message) => message.toJson()),
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    Object? lastError;

    // Deux tentatives : la seconde donne encore plus de tokens au modèle si la
    // première réponse est coupée ou produit un JSON invalide.
    for (var attempt = 1; attempt <= 2; attempt++) {
      final requestBody = <String, dynamic>{
        'model': _ollamaModel,
        'messages': messages,
        'stream': false,
        'keep_alive': '10m',
        'options': {
          'temperature': structuredPlacementTest ? 0.0 : 0.4,
          'num_ctx': 8192,
          'num_predict': structuredPlacementTest
              ? (attempt == 1 ? 4096 : 6144)
              : 1024,
        },
      };

      if (structuredPlacementTest) {
        requestBody['format'] = _placementTestJsonSchema;
      }

      debugPrint('========== OLLAMA ==========');
      debugPrint('Endpoint: $_llmEndpoint');
      debugPrint('Model: $_ollamaModel');
      debugPrint('Tentative: $attempt/2');
      debugPrint(jsonEncode(requestBody));

      try {
        final response = await http
            .post(
          Uri.parse(_llmEndpoint),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
            .timeout(const Duration(minutes: 10));

        debugPrint('StatusCode: ${response.statusCode}');
        debugPrint('Body: ${response.body}');

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'Erreur Ollama ${response.statusCode}: ${response.body}',
          );
        }

        final decoded = _decodeOllamaEnvelope(response.body);
        final doneReason = decoded['done_reason']?.toString();

        if (doneReason == 'length') {
          throw const FormatException(
            'La réponse Ollama a été coupée avant la fin.',
          );
        }

        final message = decoded['message'];
        if (message is! Map) {
          throw const FormatException(
            'Le champ message est absent de la réponse Ollama.',
          );
        }

        final reply = message['content']?.toString().trim();

        if (reply == null || reply.isEmpty) {
          throw const FormatException('Réponse Ollama vide.');
        }

        if (structuredPlacementTest) {
          // Valide et normalise le JSON avant de le rendre à l'écran du test.
          return _normalizePlacementTestJson(reply);
        }

        return reply;
      } catch (e) {
        lastError = e;
        debugPrint('Tentative Ollama $attempt échouée: $e');

        if (attempt == 2) {
          rethrow;
        }
      }
    }

    throw Exception('Échec Ollama: $lastError');
  }

  Map<String, dynamic> _decodeOllamaEnvelope(String rawBody) {
    final body = rawBody.trim();

    if (body.isEmpty) {
      throw const FormatException('Réponse HTTP Ollama vide.');
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } on FormatException {
      debugPrint('⚠️ Ollama raw response: $body');
      throw const FormatException('Réponse générale Ollama non JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'La réponse générale Ollama n’est pas un objet JSON.',
      );
    }

    return decoded;
  }

  String _normalizePlacementTestJson(String rawContent) {
    var content = rawContent.trim();

    // Sécurité supplémentaire pour les modèles qui ajoutent malgré tout un
    // bloc Markdown autour du JSON.
    if (content.startsWith('```')) {
      content = content
          .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(content);
    } on FormatException catch (e) {
      debugPrint('JSON de test invalide reçu depuis Ollama:');
      debugPrint(content);
      throw FormatException('JSON du test incomplet ou invalide: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Le test retourné doit être un objet JSON.',
      );
    }

    final questions = decoded['questions'];

    if (questions is! List || questions.length != 10) {
      throw FormatException(
        'Le test doit contenir exactement 10 questions, '
            'mais ${questions is List ? questions.length : 0} ont été reçues.',
      );
    }

    const allowedLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
    final normalizedQuestions = <Map<String, dynamic>>[];

    for (var index = 0; index < questions.length; index++) {
      final rawQuestion = questions[index];

      if (rawQuestion is! Map) {
        throw FormatException(
          'La question ${index + 1} n’est pas un objet JSON valide.',
        );
      }

      final item = Map<String, dynamic>.from(rawQuestion);
      final question = item['question']?.toString().trim() ?? '';
      final explanation = item['explanation']?.toString().trim() ?? '';
      final cefrFocus = item['cefrFocus']?.toString().trim().toUpperCase() ?? '';
      final optionsRaw = item['options'];

      if (question.isEmpty) {
        throw FormatException('La question ${index + 1} est vide.');
      }

      if (optionsRaw is! List || optionsRaw.length != 4) {
        throw FormatException(
          'La question ${index + 1} doit avoir exactement 4 options.',
        );
      }

      final options = optionsRaw
          .map((option) => option?.toString().trim() ?? '')
          .toList(growable: false);

      if (options.any((option) => option.isEmpty)) {
        throw FormatException(
          'Une option de la question ${index + 1} est vide.',
        );
      }

      final correctIndexRaw = item['correctIndex'];
      final correctIndex = correctIndexRaw is int
          ? correctIndexRaw
          : int.tryParse(correctIndexRaw?.toString() ?? '');

      if (correctIndex == null || correctIndex < 0 || correctIndex > 3) {
        throw FormatException(
          'correctIndex est invalide pour la question ${index + 1}.',
        );
      }

      if (!allowedLevels.contains(cefrFocus)) {
        throw FormatException(
          'Le niveau CECR de la question ${index + 1} est invalide.',
        );
      }

      normalizedQuestions.add({
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'cefrFocus': cefrFocus,
      });
    }

    return jsonEncode({
      'questions': normalizedQuestions,
    });
  }

  String _buildPlacementTestSystemPrompt(Map<String, dynamic> context) {
    final language = _cleanProfileValue(
      context['language'],
      fallback: 'la langue choisie par l’étudiant',
    );

    return '''
Tu es un générateur de tests de positionnement linguistique pour l'application Smart Sprachcaffe.

Langue du test : $language.

Consignes obligatoires :
- Génère exactement 10 questions.
- Chaque question possède exactement 4 options.
- Une seule option est correcte.
- correctIndex est un entier entre 0 et 3.
- Répartition : 2 questions A1, 2 questions A2, 2 questions B1, 2 questions B2, 1 question C1 et 1 question C2.
- Les questions doivent réellement tester la langue demandée.
- Les explications doivent être courtes et claires.
- Respecte exactement le schéma JSON imposé par l'API.
- Ne mets aucun texte avant ou après le JSON.
- N'utilise jamais de bloc Markdown.
''';
  }

  String _buildSystemPrompt(Map<String, dynamic> context) {
    return '''
Tu es l'assistant pédagogique officiel de l'application Smart Sprachcaffe.

Réponds en français simple, professionnel et motivant.

Ton rôle :
- aider l'étudiant à comprendre ses cours ;
- expliquer son planning ;
- l'aider concernant son niveau ;
- l'orienter vers les ressources ;
- l'aider pour les démarches d'inscription et de paiement ;
- donner des conseils pédagogiques simples.

Règles importantes :
- Ne donne pas d'informations inventées.
- Si une information n'existe pas dans le contexte, dis que l'étudiant doit vérifier avec l'administration.
- Ne donne jamais de conseils dangereux, illégaux ou hors contexte scolaire.
- Réponds directement à la question de l'étudiant.
- Ne sois pas trop long.

Contexte étudiant JSON :
${jsonEncode(context)}
''';
  }

  String _localAssistantReply(
      String message,
      Map<String, dynamic> context,
      ) {
    final lower = message.toLowerCase();
    final name = context['name']?.toString();
    final greetingName = name == null || name.trim().isEmpty ? '' : ' $name';

    if (_containsAny(lower, [
      'bonjour',
      'salut',
      'salam',
      'hello',
      'bonsoir',
    ])) {
      return 'Bonjour$greetingName 👋 Je suis ton assistant pédagogique. '
          'Je peux t’aider pour les cours, le planning, les ressources, '
          'le niveau ou le paiement.';
    }

    if (_isProfileQuestion(message)) {
      return _profileOnlyReply(context);
    }

    if (_containsAny(lower, [
      'planning',
      'séance',
      'seance',
      'horaire',
      'date',
      'salle',
    ])) {
      final sessions = context['upcomingSessions'];

      if (sessions is List && sessions.isNotEmpty) {
        final lines = sessions.take(4).map((session) {
          final item = Map<String, dynamic>.from(session as Map);
          final title = item['courseTitle'] ?? 'Cours';
          final date = item['date'] ?? 'date non définie';
          final time = item['time'] ?? 'heure non définie';
          final room = item['room'] ?? 'salle non définie';

          return '• $title : $date à $time, salle $room';
        }).join('\n');

        return 'Voici les prochaines séances disponibles dans l’application :\n'
            '$lines\n\n'
            'Pour confirmer, vérifie aussi l’onglet Planning.';
      }

      return 'Je ne trouve pas encore de séance programmée. '
          'Vérifie l’onglet Planning ou contacte l’administration.';
    }

    if (_containsAny(lower, [
      'cours',
      'formation',
      'module',
      'langue',
    ])) {
      final selectedCourses = context['selectedCourses'];
      final assignedCourses = context['assignedCourses'];

      if (assignedCourses is List && assignedCourses.isNotEmpty) {
        final lines = assignedCourses.take(4).map((course) {
          final item = Map<String, dynamic>.from(course as Map);
          final title = item['courseTitle'] ?? 'Cours';
          final level = item['level'];

          return '• $title${level != null ? ' — niveau $level' : ''}';
        }).join('\n');

        return 'D’après ton espace étudiant, voici tes cours affectés :\n'
            '$lines\n\n'
            'Tu peux ouvrir l’onglet Cours pour voir plus de détails.';
      }

      if (selectedCourses is List && selectedCourses.isNotEmpty) {
        final lines = selectedCourses.take(4).map((course) {
          final item = Map<String, dynamic>.from(course as Map);
          final langue = item['langue'] ?? 'Langue';
          final niveau = item['niveau'] ?? 'niveau non défini';
          final mode = item['mode'] ?? 'mode non défini';

          return '• $langue — $niveau — $mode';
        }).join('\n');

        return 'Voici les cours choisis lors de ton inscription :\n'
            '$lines\n\n'
            'Après validation administrative, ils pourront apparaître '
            'dans ton espace cours.';
      }

      return 'Je ne vois pas encore de cours dans ton profil. '
          'Tu peux vérifier ton inscription ou contacter l’administration.';
    }

    if (_containsAny(lower, [
      'paiement',
      'payer',
      'payé',
      'paye',
      'facture',
      'reçu',
      'recu',
    ])) {
      final isPaid = context['isPaid'];
      final paymentStatus = context['paymentStatus']?.toString();

      if (isPaid == true || paymentStatus?.toLowerCase() == 'paid') {
        return 'Ton paiement semble validé dans l’application ✅. '
            'Tu peux accéder normalement à ton espace étudiant.';
      }

      return 'Ton paiement n’est pas encore confirmé dans l’application. '
          'Va dans la page Paiement ou contacte l’administration pour validation.';
    }

    if (_containsAny(lower, [
      'niveau',
      'test',
      'a1',
      'a2',
      'b1',
      'b2',
      'c1',
      'débutant',
    ])) {
      final level = context['level']?.toString();
      final language = context['language']?.toString();

      if (level != null && level.isNotEmpty) {
        return 'Ton niveau enregistré est $level'
            '${language != null && language.isNotEmpty ? ' en $language' : ''}. '
            'Pour progresser, révise régulièrement le vocabulaire, '
            'l’écoute et l’expression orale.';
      }

      return 'Pour connaître ton niveau, utilise le test de niveau dans l’application. '
          'Après le test, tu pourras mieux choisir le cours adapté.';
    }

    if (_containsAny(lower, [
      'ressource',
      'pdf',
      'document',
      'support',
      'cours pdf',
    ])) {
      return 'Les ressources de cours sont disponibles dans l’onglet Ressources. '
          'Tu peux y trouver les documents PDF ajoutés par le professeur.';
    }

    if (_containsAny(lower, [
      'oral',
      'speaking',
      'parler',
      'conversation',
      'prononciation',
    ])) {
      return 'Pour améliorer ton oral, pratique 15 minutes par jour : '
          'lis à voix haute, répète des dialogues, enregistre ta voix, '
          'puis participe aux séances de conversation quand elles sont disponibles.';
    }

    if (_containsAny(lower, [
      'écrit',
      'ecrit',
      'writing',
      'rédaction',
      'redaction',
    ])) {
      return 'Pour améliorer l’écrit, commence par des phrases simples, '
          'révise la grammaire de base, puis écris un petit paragraphe chaque jour. '
          'Tu peux aussi demander au professeur de corriger tes textes.';
    }

    return 'J’ai compris ta question. Pour le moment, je peux t’aider sur : '
        'cours, planning, paiement, niveau, ressources et conseils de révision.';
  }

  bool _isPlacementTestGenerationRequest(String message) {
    final lower = message.toLowerCase();

    final mentionsPlacementTest = _containsAny(lower, [
      'test de positionnement',
      'test de niveau',
      'placement test',
    ]);

    final asksForGeneration = _containsAny(lower, [
      'génère',
      'genere',
      'générer',
      'generer',
      'crée',
      'cree',
      'créer',
      'creer',
      'produis',
      'questions',
      'correctindex',
      'cefrfocus',
      'json',
    ]);

    return mentionsPlacementTest && asksForGeneration;
  }

  bool _isProfileQuestion(String message) {
    final lower = message.toLowerCase();

    return _containsAny(lower, [
      'qui suis',
      'qui moi',
      'c est qui moi',
      'c\'est qui moi',
      'c’est qui moi',
      'mon profil',
      'profile',
      'profil',
      'mes informations',
      'mes infos',
      'information personnelle',
      'infos personnelles',
    ]);
  }

  String _profileOnlyReply(Map<String, dynamic> context) {
    if (context['isLoggedIn'] != true) {
      return 'Tu n’es pas connecté. Connecte-toi pour afficher les informations de ton profil.';
    }

    final name = _cleanProfileValue(context['name'], fallback: 'Non défini');
    final email = _cleanProfileValue(context['email'], fallback: 'Non défini');
    final role = _formatRole(context['role']);

    final language = _cleanProfileValue(
      context['language'],
      fallback: 'Non défini',
    );

    final level = _cleanProfileValue(
      context['level'],
      fallback: 'Non défini',
    );

    final profileCompleted =
    context['profileCompleted'] == true ? 'Complet' : 'Non complet';

    final isPaid = context['isPaid'] == true;

    final paymentStatus = _cleanProfileValue(
      context['paymentStatus'],
      fallback: 'Non défini',
    );

    final paymentText = isPaid ? 'Validé' : 'Non validé';

    return '''Voici les informations de ton profil :

Nom : $name
Email : $email
Rôle : $role
Langue : $language
Niveau : $level
Profil : $profileCompleted
Paiement : $paymentText
Statut paiement : $paymentStatus''';
  }

  String _cleanProfileValue(dynamic value, {required String fallback}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _formatRole(dynamic value) {
    final role = _cleanProfileValue(value, fallback: 'Étudiant');

    switch (role.toLowerCase()) {
      case 'student':
        return 'Étudiant';
      case 'teacher':
        return 'Professeur';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  bool _containsAny(String text, List<String> words) {
    return words.any(text.contains);
  }
}
