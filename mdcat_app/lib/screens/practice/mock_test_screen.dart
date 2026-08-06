import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  final _difficulties = ["Easy", "Medium", "Hard"];

  @override
  void initState() {
    super.initState();
    _totalQuestions = widget.presetTotalQuestions ?? 100;
    _quizMinutes = widget.presetMinutes ?? 150;
  }

  bool get _isPreset => widget.presetTotalQuestions != null;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final quizSet = await _api.generateMockTest(
        totalQuestions: _totalQuestions,
        difficulty: _difficulty,
        quizMinutes: _quizMinutes,
        examType: widget.examType,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.examType ??
        context.watch<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return Scaffold(
      appBar: AppBar(title: Text("$exam ${widget.title}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(mockTestDescription(exam), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 24),
            if (!_isPreset) ...[
              Text("Total Questions: $_totalQuestions",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _totalQuestions.toDouble(),
                min: 20,
                max: 200,
                divisions: 18,
                label: "$_totalQuestions",
                onChanged: (v) => setState(() => _totalQuestions = v.round()),
              ),
              const SizedBox(height: 8),
              Text("Time Limit: $_quizMinutes min",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _quizMinutes.toDouble(),
                min: 20,
                max: 210,
                divisions: 19,
                label: "$_quizMinutes",
                onChanged: (v) => setState(() => _quizMinutes = v.round()),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text("$_totalQuestions questions • $_quizMinutes minutes",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            const Text("Difficulty", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Generate Test"),
            ),
          ],
        ),
      ),
    );
  }
}
