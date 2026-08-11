import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home_navigation_action.dart';
import '../tutor/tutor_chat_screen.dart';
import 'practice_by_topic_screen.dart';

class ExamFormatScreen extends StatefulWidget {
  final String? examType;

  const ExamFormatScreen({super.key, this.examType});

  @override
  State<ExamFormatScreen> createState() => _ExamFormatScreenState();
}

class _ExamFormatScreenState extends State<ExamFormatScreen> {
  final ApiClient _api = ApiClient();
  ExamFormat? _format;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _api.getExamFormat(examType: widget.examType);
      if (mounted) setState(() => _format = value);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _openSection(ExamSection section) {
    if (section.kind == 'mcq') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeByTopicScreen(
            examType: widget.examType,
            initialSubject: section.name,
          ),
        ),
      );
      return;
    }
    final prompt =
        '''Start a structured ${_format!.examType} ${section.name} preparation session.
Teach me the official section format, give me one realistic practice task, let me answer, then give feedback using the correct scoring criteria. Keep the session focused only on ${_format!.examType} ${section.name}.''';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TutorChatScreen(initialMessage: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text('Exam Format'),
        actions: const [HomeNavigationAction()],
      ),
      body: _error != null
          ? Center(child: Text("Couldn't load format: $_error"))
          : _format == null
          ? const Center(child: CircularProgressIndicator())
          : _body(_format!),
    );
  }

  Widget _body(ExamFormat format) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        format.title,
        style: TextStyle(
          color: context.primaryTextColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        '${format.version} • ${format.delivery}',
        style: TextStyle(color: context.secondaryTextColor),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _stat(
              Icons.timer_outlined,
              '${format.durationMinutes} min',
              'Duration',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stat(
              Icons.help_outline,
              '${format.totalQuestions}',
              'Questions/tasks',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stat(
              Icons.remove_circle_outline,
              format.negativeMarking == 0
                  ? 'None'
                  : '-${format.negativeMarking}',
              'Negative marking',
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        'Sections',
        style: TextStyle(
          color: context.primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      ...format.sections.map(
        (section) => Card(
          color: context.panelColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0x1F20D5C5),
              child: Icon(_icon(section.kind), color: const Color(0xFF20D5C5)),
            ),
            title: Text(section.name),
            subtitle: Text(
              [
                section.kind.toUpperCase(),
                if (section.questions != null)
                  '${section.questions} questions/tasks',
                if (section.minutes != null) '${section.minutes} min',
              ].join(' • '),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
            onTap: () => _openSection(section),
          ),
        ),
      ),
      if (format.notes.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          'Important notes',
          style: TextStyle(
            color: context.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        ...format.notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $note',
              style: TextStyle(color: context.secondaryTextColor),
            ),
          ),
        ),
      ],
      if (format.officialSource != null) ...[
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(format.officialSource!),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Open Official Format Source'),
        ),
      ],
    ],
  );

  Widget _stat(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: context.panelColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.subtleBorderColor),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF20D5C5)),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.secondaryTextColor, fontSize: 9),
        ),
      ],
    ),
  );

  IconData _icon(String kind) {
    switch (kind) {
      case 'listening':
        return Icons.headphones;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit_note;
      case 'speaking':
        return Icons.record_voice_over;
      default:
        return Icons.checklist;
    }
  }
}
