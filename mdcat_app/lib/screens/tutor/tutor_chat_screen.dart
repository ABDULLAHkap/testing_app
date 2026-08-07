import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

const _cyan = Color(0xFF20D5C5);

class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({super.key});

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_TutorMessage> _messages = [];
  bool _sending = false;

  Color get _bg => context.pageBackground;
  Color get _surface => context.panelColor;
  Color get _text => context.primaryTextColor;
  Color get _muted => context.secondaryTextColor;

  String get _exam =>
      context.read<AuthProvider>().currentUser?.targetExam ?? 'your exam';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _TutorMessage(
            isUser: false,
            text:
                'Welcome! I am your $_exam tutor. I can explain questions, '
                'teach syllabus topics, build a study plan, and guide you '
                'through tests in this app. What would you like to learn?',
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedMessage]) async {
    final text = (suggestedMessage ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;
    _messageController.clear();

    final history = _messages
        .skip(1)
        .map(
          (item) => {
            'role': item.isUser ? 'user' : 'assistant',
            // Keep detailed plans in context while ensuring an unexpectedly
            // long response can never break the next request.
            'content': item.text.length > 5500
                ? item.text.substring(0, 5500)
                : item.text,
          },
        )
        .toList();

    setState(() {
      _messages.add(_TutorMessage(isUser: true, text: text));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final result = await _api.askTutor(text, history);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _TutorMessage(
            isUser: false,
            text:
                result['reply']?.toString() ??
                'I could not prepare a response. Please try again.',
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _TutorMessage(isUser: false, isError: true, text: error.toString()),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x1820D5C5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined, color: _cyan, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Tutor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Focused on $_exam',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _scopeNotice(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return _typingBubble();
                  }
                  return _messageBubble(_messages[index]);
                },
              ),
            ),
            if (_messages.length <= 1) _quickPrompts(),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _scopeNotice() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0x141FAF8C),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _cyan.withOpacity(.25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_user_outlined, color: _cyan, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This tutor answers only $_exam preparation and app-guidance questions.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _messageBubble(_TutorMessage message) {
    final color = message.isUser
        ? const Color(0xFF147D75)
        : message.isError
        ? const Color(0xFF4A2028)
        : _surface;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser
              ? null
              : Border.all(color: context.subtleBorderColor),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: message.isUser || message.isError ? Colors.white : _text,
            fontSize: 14,
            height: 1.42,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 36,
        child: LinearProgressIndicator(
          color: _cyan,
          backgroundColor: context.subtleBorderColor,
        ),
      ),
    ),
  );

  Widget _quickPrompts() {
    final prompts = [
      'How should I start preparing for $_exam?',
      'Make a 7-day study plan',
      'How do I use mock tests?',
      'What should I study today?',
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ActionChip(
          label: Text(prompts[index]),
          labelStyle: const TextStyle(color: _cyan, fontSize: 11),
          backgroundColor: _surface,
          side: BorderSide(color: _cyan.withOpacity(.3)),
          onPressed: () => _send(prompts[index]),
        ),
      ),
    );
  }

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
    decoration: BoxDecoration(
      color: _surface,
      border: Border(top: BorderSide(color: context.subtleBorderColor)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            enabled: !_sending,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Ask about $_exam...',
              hintStyle: TextStyle(color: context.inactiveColor),
              filled: true,
              fillColor: _bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _sending ? null : _send,
          style: IconButton.styleFrom(
            backgroundColor: _cyan,
            foregroundColor: const Color(0xFF031018),
          ),
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    ),
  );
}

class _TutorMessage {
  final bool isUser;
  final String text;
  final bool isError;

  const _TutorMessage({
    required this.isUser,
    required this.text,
    this.isError = false,
  });
}
