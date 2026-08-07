import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../quiz/quiz_screen.dart';
import 'exam_format_screen.dart';

class AdaptivePracticeScreen extends StatefulWidget {
  const AdaptivePracticeScreen({super.key});

  @override
  State<AdaptivePracticeScreen> createState() => _AdaptivePracticeScreenState();
}

class _AdaptivePracticeScreenState extends State<AdaptivePracticeScreen> {
  final ApiClient _api = ApiClient();
  AdvancedAnalytics? _analytics;
  ExamFormat? _format;
  bool _loading = true;
  bool _generating = false;
  int _questions = 15;
  int _minutes = 25;
  String _difficulty = 'Medium';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        _api.getAdvancedAnalytics(),
        _api.getExamFormat(),
      ]);
      if (mounted) {
        setState(() {
          _analytics = values[0] as AdvancedAnalytics;
          _format = values[1] as ExamFormat;
        });
      }
    } catch (_) {
      // Fetch the format separately so a new learner without analytics still
      // receives the correct section-based experience.
      try {
        final format = await _api.getExamFormat();
        if (mounted) setState(() => _format = format);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final quiz = await _api.generateAdaptivePractice(
        numberOfQuestions: _questions,
        quizMinutes: _minutes,
        difficulty: _difficulty,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quiz)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't generate practice: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weak = _analytics?.weakestTopics ?? const <PerformanceMetric>[];
    final supportsMcqPractice = _format?.supportsFullMcqMock ?? true;
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(title: const Text('Adaptive Practice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !supportsMcqPractice
          ? ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.panelColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.subtleBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        color: Color(0xFF20D5C5),
                        size: 34,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_format!.examType} needs section-based practice',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A generic adaptive MCQ set would not match the real exam. Practise each official section in its correct mode instead.',
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => ExamFormatScreen(
                                    examType: _format!.examType,
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Open Section Practice'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.panelColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.subtleBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_graph, color: Color(0xFF20D5C5)),
                          SizedBox(width: 8),
                          Text(
                            'Personal practice mix',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weak.isEmpty
                            ? 'Complete a test to identify weak topics. This first set will cover your syllabus evenly.'
                            : 'More questions will come from your weaker topics. Mastered topics stay in the mix with fewer questions.',
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                      if (weak.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: weak
                              .take(5)
                              .map(
                                (item) => Chip(
                                  label: Text(
                                    '${item.name} ${item.accuracy.toStringAsFixed(0)}%',
                                  ),
                                  avatar: const Icon(
                                    Icons.priority_high,
                                    size: 16,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Questions: $_questions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _questions.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (value) =>
                      setState(() => _questions = value.round()),
                ),
                Text(
                  'Time: $_minutes minutes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _minutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (value) =>
                      setState(() => _minutes = value.round()),
                ),
                const Text(
                  'Difficulty',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _difficulty,
                  isExpanded: true,
                  items: const ['Easy', 'Medium', 'Hard']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _difficulty = value!),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _generating
                        ? 'Preparing your set...'
                        : 'Start Adaptive Practice',
                  ),
                ),
              ],
            ),
    );
  }
}
