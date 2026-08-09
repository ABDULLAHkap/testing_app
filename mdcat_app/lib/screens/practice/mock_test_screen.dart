import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../utils/exam_content.dart';
import '../quiz/quiz_screen.dart';

class MockTestScreen extends StatefulWidget {
  final int? presetTotalQuestions;
  final int? presetMinutes;
  final String title;
  final String? examType;

  const MockTestScreen({
    super.key,
    this.presetTotalQuestions,
    this.presetMinutes,
    this.title = "Full Mock Test",
    this.examType,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  final ApiClient _api = ApiClient();

  late int _totalQuestions;
  late int _quizMinutes;
  String _difficulty = "Medium";
  bool _generating = false;
  bool _loadingFormat = true;
  ExamFormat? _format;

  final _difficulties = ["Easy", "Medium", "Hard"];

  @override
  void initState() {
    super.initState();
    _totalQuestions = widget.presetTotalQuestions ?? 100;
    _quizMinutes = widget.presetMinutes ?? 150;
    _loadFormat();
  }

  bool get _isPreset => widget.presetTotalQuestions != null;

  Future<void> _loadFormat() async {
    try {
      final format = await _api.getExamFormat(examType: widget.examType);
      if (!mounted) return;
      setState(() {
        _format = format;
        if (!_isPreset) {
          _totalQuestions = format.totalQuestions;
          _quizMinutes = format.durationMinutes;
        }
      });
    } catch (_) {
      // The generator still provides its existing custom fallback.
    } finally {
      if (mounted) setState(() => _loadingFormat = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final quizSet = await _api.generateMockTest(
        totalQuestions: _totalQuestions,
        difficulty: _difficulty,
        quizMinutes: _quizMinutes,
        examType: widget.examType,
        officialFormat: !_isPreset,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam =
        widget.examType ??
        context.watch<AuthProvider>().currentUser?.targetExam ??
        "Exam";
    if (_loadingFormat) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text("$exam ${widget.title}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mockTestDescription(exam),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (!_isPreset) ...[
              Text(
                _format?.supportsFullMcqMock == true
                    ? 'Official ${_format?.version ?? ''} format'
                    : '$exam objective practice format',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('$_totalQuestions questions • $_quizMinutes minutes'),
              Text(
                (_format?.negativeMarking ?? 0) == 0
                    ? 'No negative marking'
                    : '${_format!.negativeMarking} deducted per wrong answer',
              ),
              if (_format?.supportsFullMcqMock == false)
                const Text(
                  'Writing, speaking or other descriptive sections remain available under Official Exam Format.',
                ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                "$_totalQuestions questions • $_quizMinutes minutes",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              "Difficulty",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _difficulty,
              isExpanded: true,
              items: _difficulties
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generating ? null : _generate,
              child: _generating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Generate Test"),
            ),
          ],
        ),
      ),
    );
  }
}
