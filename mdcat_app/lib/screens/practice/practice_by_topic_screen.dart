import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../models/models.dart';
import '../../widgets/home_navigation_action.dart';
import '../quiz/quiz_screen.dart';

class PracticeByTopicScreen extends StatefulWidget {
  final String? examType;
  final String? initialSubject;

  const PracticeByTopicScreen({super.key, this.examType, this.initialSubject});

  @override
  State<PracticeByTopicScreen> createState() => _PracticeByTopicScreenState();
}

class _PracticeByTopicScreenState extends State<PracticeByTopicScreen> {
  final ApiClient _api = ApiClient();

  List<TopicListItem> _syllabus = [];
  bool _loadingSyllabus = true;
  String? _error;

  String? _selectedSubject;
  String? _selectedTopic;
  String _difficulty = "Medium";
  int _count = 10;
  int _quizMinutes = 20;
  bool _generating = false;

  final _difficulties = ["Easy", "Medium", "Hard"];

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    try {
      final subjects = await _api.getSubjects(examType: widget.examType);
      setState(() {
        _syllabus = subjects;
        if (widget.initialSubject != null &&
            subjects.any((item) => item.subject == widget.initialSubject)) {
          _selectedSubject = widget.initialSubject;
        }
        _loadingSyllabus = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSyllabus = false;
      });
    }
  }

  List<String> get _topicsForSelectedSubject {
    final match = _syllabus.where((s) => s.subject == _selectedSubject);
    if (match.isEmpty) return [];
    return match.first.topics;
  }

  Future<void> _generate() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Choose a subject first")));
      return;
    }
    setState(() => _generating = true);
    try {
      final quizSet = await _api.generateMcqs(
        numberOfQuestions: _count,
        subject: _selectedSubject!,
        topic: _selectedTopic,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Practice by Topic"),
        actions: const [HomeNavigationAction()],
      ),
      body: _loadingSyllabus
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Couldn't load subjects: $_error"))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Subject",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _syllabus.map((s) {
                        final selected = s.subject == _selectedSubject;
                        return ChoiceChip(
                          label: Text(s.subject),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _selectedSubject = s.subject;
                            _selectedTopic = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedSubject != null) ...[
                      const Text(
                        "Topic (optional — leave blank for a mixed set)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _topicsForSelectedSubject.map((t) {
                          final selected = t == _selectedTopic;
                          return ChoiceChip(
                            label: Text(t),
                            selected: selected,
                            onSelected: (_) => setState(
                              () => _selectedTopic = selected ? null : t,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      "Difficulty",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _difficulty,
                      isExpanded: true,
                      items: _difficulties
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Number of Questions: $_count",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _count.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: "$_count",
                      onChanged: (v) => setState(() => _count = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Time Limit: $_quizMinutes min",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quizMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: "$_quizMinutes",
                      onChanged: (v) =>
                          setState(() => _quizMinutes = v.round()),
                    ),
                    const SizedBox(height: 20),
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
                          : const Text("Generate Quiz"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
