import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/file_saver.dart';
import '../../widgets/animated_hero_image.dart';
import '../home/home_screen.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't download PDF: $e")));
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

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Result"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedHeroImage(
              asset: 'assets/images/results_trophy.webp',
              height: 190,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(18),
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Text(
                    "${r.percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                        fontSize: 42, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _gradeColor(r.grade).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Grade: ${r.grade}",
                      style: TextStyle(
                        color: _gradeColor(r.grade),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                    child: _statCard("Total", "${r.total}", Colors.blueGrey)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard("Correct", "${r.correct}", Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _statCard("Wrong", "${r.wrong}", Colors.red)),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Subject: ${widget.subject}"),
                    Text("Difficulty: ${widget.difficulty}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (r.review.isNotEmpty) ...[
              const Text(
                "Answer Review",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...r.review.map(_reviewCard),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadPdf,
              icon: _downloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label:
                  Text(_downloading ? "Downloading..." : "Download Result PDF"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text("Back to Dashboard"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${item.index + 1}. ${item.question}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Your answer: $selected'),
            Text(
              'Correct answer: ${item.correctAnswer}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
            if (item.explanation != null && item.explanation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Explanation: ${item.explanation}'),
            ],
          ],
        ),
      ),
    );
  }
}
