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
  static const _bg = Color(0xFF061320);
  static const _surface = Color(0xFF101F32);
  static const _cyan = Color(0xFF20D5C5);

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
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Test Results"),
        backgroundColor: _bg,
        centerTitle: true,
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
                    r.percentage >= 80 ? 'Excellent Work' : r.percentage >= 60 ? 'Well Done' : 'Keep Practicing',
                    style: const TextStyle(color: _cyan, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 155,
                    height: 155,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(child: CircularProgressIndicator(
                        value: (r.percentage / 100).clamp(0, 1).toDouble(),
                        strokeWidth: 14,
                        backgroundColor: const Color(0xFF25354A),
                        color: _cyan,
                      )),
                      Text(
                        "${r.percentage.toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Grade ${r.grade} • ${widget.subject}",
                    style: TextStyle(color: _gradeColor(r.grade), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                    child: _statCard("Correct", "${r.correct}", const Color(0xFF35D58A), Icons.check_circle)),
                const SizedBox(width: 10),
                Expanded(child: _statCard("Incorrect", "${r.wrong}", const Color(0xFFFF515D), Icons.cancel)),
                const SizedBox(width: 10),
                Expanded(child: _statCard("Total", "${r.total}", const Color(0xFF45A8FF), Icons.fact_check_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            if (r.review.isNotEmpty) ...[
              const Row(children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Icon(Icons.assignment_outlined, color: _cyan), SizedBox(width: 7), Text("Question Review", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))])),
                Expanded(child: Divider(color: Colors.white24)),
              ]),
              const SizedBox(height: 14),
              ...r.review.take(3).map(_reviewCard),
              if (r.review.length > 3) TextButton.icon(
                onPressed: () => _showFullReview(r.review),
                icon: const Icon(Icons.list_alt),
                label: const Text('Review All Answers'),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(height: 56, child: ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadPdf,
              icon: _downloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(_downloading ? "Downloading..." : "Download Result PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: const Color(0xFF031018)),
            )),
            const SizedBox(height: 12),
            SizedBox(height: 56, child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text("Back to Home"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
            )),
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
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: statusColor.withOpacity(.75))),
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
            Text('Your answer: $selected', style: const TextStyle(color: Colors.white70)),
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
            const Center(child: Text('All Answers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 18),
            ...review.map(_reviewCard),
          ],
        ),
      ),
    );
  }
}
