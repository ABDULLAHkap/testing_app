import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/file_saver.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_hero_image.dart';
import '../../widgets/home_navigation_action.dart';
import '../home/home_screen.dart';
import '../tutor/tutor_chat_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final AttemptResult result;
  final String subject;
  final String difficulty;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.subject,
    required this.difficulty,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final ApiClient _api = ApiClient();
  bool _downloading = false;
  static const _cyan = Color(0xFF20D5C5);

  Color get _bg => context.pageBackground;
  Color get _surface => context.panelColor;
  Color get _text => context.primaryTextColor;
  Color get _muted => context.secondaryTextColor;

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await _api.downloadResultPdf(widget.result.id);
      await savePdf(bytes, "Exam_Result_${widget.result.id}.pdf");
      // On mobile, savePdf() opens the native Share sheet directly, so no
      // extra snackbar is needed there. On web it triggers a browser
      // download, where a confirmation is still useful.
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't download PDF: $e")));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case "A+":
      case "A":
        return Colors.green;
      case "B":
        return Colors.lightGreen;
      case "C":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _duration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _explain(QuestionReview item) {
    final optionDetails = item.options
        .map((option) {
          final letter = option.trim().isEmpty ? '' : option.trim()[0];
          final known = item.optionExplanations[letter];
          return known == null ? option : '$option — stored note: $known';
        })
        .join('\n');
    final questionContext =
        '''Question: ${item.question}

Choices:
$optionDetails
My answer: ${item.selectedOption ?? 'Not answered'}
Correct answer: ${item.correctOption} — ${item.correctAnswer}
Known explanation: ${item.explanation ?? 'None'}
Topic: ${item.topic ?? 'Not labelled'}
Concept: ${item.concept ?? 'Not labelled'}''';
    final safeContext = questionContext.length > 1400
        ? questionContext.substring(0, 1400)
        : questionContext;
    final prompt =
        '''Explain this exact ${item.subject ?? widget.subject} question for my exam:

$safeContext

Please explain in four short parts:
1. Why the correct answer is right.
2. Why each other choice is wrong.
3. The concept I should revise.
4. One quick exam tip or mini example.''';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TutorChatScreen(initialMessage: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Test Results"),
        backgroundColor: _bg,
        centerTitle: true,
        actions: const [HomeNavigationAction()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedHeroImage(
              asset: 'assets/images/results_trophy.webp',
              height: 260,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(22),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    r.percentage >= 80
                        ? 'Excellent Work'
                        : r.percentage >= 60
                        ? 'Well Done'
                        : 'Keep Practicing',
                    style: const TextStyle(
                      color: _cyan,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 155,
                    height: 155,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: (r.percentage / 100).clamp(0, 1).toDouble(),
                            strokeWidth: 14,
                            backgroundColor: context.subtleBorderColor,
                            color: _cyan,
                          ),
                        ),
                        Text(
                          "${r.percentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: _text,
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Grade ${r.grade} • ${widget.subject}",
                    style: TextStyle(
                      color: _gradeColor(r.grade),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    "Correct",
                    "${r.correct}",
                    const Color(0xFF35D58A),
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    "Incorrect",
                    "${r.wrong}",
                    const Color(0xFFFF515D),
                    Icons.cancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    "Time",
                    _duration(r.totalTimeSeconds),
                    const Color(0xFF45A8FF),
                    Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            if (r.negativeMarking > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Net score: ${r.score.toStringAsFixed(2)} / ${r.maxScore.toStringAsFixed(0)} • ${r.negativeMarking.toStringAsFixed(2)} deducted per wrong answer',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            if (r.review.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: Divider(color: context.subtleBorderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: _cyan),
                        const SizedBox(width: 7),
                        Text(
                          "Question Review",
                          style: TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Divider(color: context.subtleBorderColor)),
                ],
              ),
              const SizedBox(height: 14),
              ...r.review.take(3).map(_reviewCard),
              if (r.review.length > 3)
                TextButton.icon(
                  onPressed: () => _showFullReview(r.review),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Review All Answers'),
                ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _downloading ? null : _downloadPdf,
                icon: _downloading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _downloading ? "Downloading..." : "Download Result PDF",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: const Color(0xFF031018),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text("Back to Home"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: BorderSide(color: context.subtleBorderColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _reviewCard(QuestionReview item) {
    final statusColor = item.isCorrect ? Colors.green : Colors.red;
    final selected = item.selectedOption == null
        ? "Not answered"
        : item.options.firstWhere(
            (option) => option.trim().startsWith('${item.selectedOption})'),
            orElse: () => item.selectedOption!,
          );
    return Card(
      color: _surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  item.isCorrect ? 'Correct' : 'Wrong',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${item.index + 1}. ${item.question}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Your answer: $selected', style: TextStyle(color: _muted)),
            Text(
              'Correct answer: ${item.correctAnswer}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.explanation != null && item.explanation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Explanation: ${item.explanation}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.concept?.isNotEmpty == true)
                  Chip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text('Revise: ${item.concept}'),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 16),
                  label: Text(_duration(item.timeSpentSeconds)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _explain(item),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Explain This Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullReview(List<QuestionReview> review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: Text(
                'All Answers',
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...review.map(_reviewCard),
          ],
        ),
      ),
    );
  }
}
