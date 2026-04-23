import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';

class StudentChatbotPage extends StatelessWidget {
  const StudentChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    const messages = [
      {
        'sender': 'assistant',
        'text': 'Bonjour Sara, je peux t’aider à choisir un cours, comprendre ton planning ou réviser un point précis.',
      },
      {
        'sender': 'user',
        'text': 'Quel cours me recommandes-tu pour améliorer mon oral ?',
      },
      {
        'sender': 'assistant',
        'text': 'Je te conseille Français conversation et l’atelier speaking du mercredi, car ils renforcent la fluidité et la confiance.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant pédagogique'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isAssistant = message['sender'] == 'assistant';
                return Align(
                  alignment: isAssistant
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isAssistant ? Colors.white : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      message['text']!,
                      style: const TextStyle(
                        height: 1.45,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Écris une question...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Envoyer',
                  icon: Icons.send_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Branche ici ton vrai chatbot IA.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
