import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/llm_chat_service.dart';

class StudentChatbotPage extends StatefulWidget {
  const StudentChatbotPage({super.key});

  @override
  State<StudentChatbotPage> createState() => _StudentChatbotPageState();
}

class _StudentChatbotPageState extends State<StudentChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LlmChatService _chatService = LlmChatService();

  final List<_ChatBubbleData> _messages = [
    const _ChatBubbleData(
      role: 'assistant',
      text:
      'Bonjour 👋 Je suis ton assistant pédagogique LLM. Pose-moi une question sur tes cours, ton planning, ton niveau, tes ressources ou ton paiement.',
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatBubbleData(role: 'user', text: text));
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((message) => message.role == 'user' || message.role == 'assistant')
          .map(
            (message) => LlmChatMessage(
          role: message.role,
          content: message.text,
        ),
      )
          .toList();

      final reply = await _chatService.sendMessage(
        userMessage: text,
        history: history,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatBubbleData(role: 'assistant', text: reply));
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatBubbleData(
            role: 'assistant',
            text: 'Désolé, une erreur est survenue : $e',
          ),
        );
        _isSending = false;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistant pédagogique LLM'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle discussion',
            onPressed: _isSending
                ? null
                : () {
              setState(() {
                _messages
                  ..clear()
                  ..add(
                    const _ChatBubbleData(
                      role: 'assistant',
                      text:
                      'Nouvelle discussion lancée. Comment puis-je t’aider ?',
                    ),
                  );
              });
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _HeaderCard(),
          _SuggestionsRow(onSuggestionTap: _sendSuggestion),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return const _TypingBubble();
                }

                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          _InputArea(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleData {
  const _ChatBubbleData({
    required this.role,
    required this.text,
  });

  final String role;
  final String text;
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.dark,
            child: Icon(Icons.smart_toy_rounded),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant IA du centre',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aide personnalisée pour apprendre et s’organiser.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  const _SuggestionsRow({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Quel est mon planning ?',
      'Quels sont mes cours ?',
      'Comment améliorer mon oral ?',
      'Mon paiement est-il validé ?',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];

          return ActionChip(
            label: Text(suggestion),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => onSuggestionTap(suggestion),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatBubbleData message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == 'assistant';

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isAssistant ? Colors.white : AppColors.primarySoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAssistant ? 4 : 20),
            bottomRight: Radius.circular(isAssistant ? 20 : 4),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: AppColors.dark,
            height: 1.45,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('L’assistant réfléchit...'),
          ],
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Écris ta question...',
                  filled: true,
                  fillColor: AppColors.background,
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              heroTag: 'sendChatbotMessage',
              onPressed: isSending ? null : onSend,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
              child: isSending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
