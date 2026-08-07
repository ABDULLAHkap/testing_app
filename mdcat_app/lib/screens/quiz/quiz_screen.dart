import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizSet quizSet;
  const QuizScreen({super.key, required this.quizSet});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiClient _api = ApiClient();

  int? _attemptId;
  bool _starting = true;
  bool _submitting = false;
  String? _error;

  int _index = 0;
  final Map<int, String> _answers = {}; // question index -> "A"/"B"/"C"/"D"
  final Map<int, int> _questionTimes = {}; // seconds spent per question

  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(minutes: widget.quizSet.quizMinutes);
    _startAttempt();
  }

  Future<void> _startAttempt() async {
    try {
      final attempt = await _api.startAttempt(widget.quizSet.id);
      setState(() {
        _attemptId = attempt.id;
        _starting = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  void _tick() {
    if (_remaining.inSeconds <= 0) {
      _timer?.cancel();
      _submit(auto: true);
      return;
    }
    setState(() {
      _remaining -= const Duration(seconds: 1);
      _questionTimes[_index] = (_questionTimes[_index] ?? 0) + 1;
    });
  }

  String _letterFor(String optionText) {
    // Options are stored like "A) Some text" — extract the leading letter.
    return optionText.trim().substring(0, 1);
  }

  Future<void> _submit({bool auto = false}) async {
    if (_attemptId == null || _submitting) return;
    _timer?.cancel();
    setState(() => _submitting = true);

    try {
      final result = await _api.submitAttempt(
        _attemptId!,
        _answers,
        _questionTimes,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            result: result,
            subject: widget.quizSet.subject,
            difficulty: widget.quizSet.difficulty,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't submit: $e")));
    }
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave quiz?"),
        content: const Text("Your progress on this attempt will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: Center(child: Text("Couldn't start quiz: $_error")),
      );
    }

    final questions = widget.quizSet.questions;
    final question = questions[_index];
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Question ${_index + 1} of ${questions.length}"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / questions.length,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (question.topic != null || question.subject != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          question.subject,
                          question.topic,
                        ].whereType<String>().toSet().join(' • '),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ...question.options.map((option) {
                      final letter = _letterFor(option);
                      final selected = _answers[_index] == letter;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setState(() => _answers[_index] = letter),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.06)
                                  : null,
                            ),
                            child: Text(option),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _index--),
                        child: const Text("Previous"),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_index < questions.length - 1) {
                                setState(() => _index++);
                              } else {
                                _submit();
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _index < questions.length - 1
                                  ? "Next"
                                  : "Finish Quiz",
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
