import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../services/file_saver.dart';
import '../../theme/app_theme.dart';
import '../quiz/quiz_screen.dart';

const _subjectColors = {
  "Biology": Color(0xFF1D9E75),
  "Chemistry": Color(0xFF7C5CFF),
  "Physics": Color(0xFF378ADD),
  "English": Color(0xFFE0A429),
  "Logical Reasoning": Color(0xFF64748B),
};

class PastPaperDetailScreen extends StatefulWidget {
  final String paperId;
  const PastPaperDetailScreen({super.key, required this.paperId});

  @override
  State<PastPaperDetailScreen> createState() => _PastPaperDetailScreenState();
}

class _PastPaperDetailScreenState extends State<PastPaperDetailScreen> {
  final ApiClient _api = ApiClient();
  PastPaperDetail? _detail;
  bool _loading = true;
  bool _generating = false;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _api.getPastPaperDetail(widget.paperId);
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startTest() async {
    setState(() => _generating = true);
    try {
      final quizSet = await _api.generateFromPastPaper(widget.paperId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't generate test: $e")));
      setState(() => _generating = false);
    }
  }

  Future<void> _downloadPaper() async {
    setState(() => _downloading = true);
    try {
      final bytes = await _api.downloadPastPaper(widget.paperId);
      await savePdf(
        bytes,
        '${_detail!.examType.replaceAll(' ', '_')}_Practice_${_detail!.year}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't download paper: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _openOfficial() async {
    final url = _detail?.officialSource;
    if (url == null ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the official source")),
        );
      }
    }
  }

  String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "$m min";
    if (m == 0) return "$h hr";
    return "$h hr $m min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text("Test Details"),
        backgroundColor: context.pageBackground,
        foregroundColor: context.primaryTextColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                "Couldn't load: $_error",
                style: TextStyle(color: context.secondaryTextColor),
              ),
            )
          : _buildContent(),
      bottomNavigationBar: _detail == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _detail!.isOfficial
                      ? _openOfficial
                      : (_generating ? null : _startTest),
                  child: _generating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _detail!.isOfficial
                              ? "Open Official Source"
                              : "Start Practice Test",
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final exam = context.read<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.isOfficial
                        ? 'OFFICIAL SOURCE'
                        : 'ORIGINAL PRACTICE • ${d.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _bannerStat(
                      Icons.help_outline,
                      "${d.totalQuestions} Items/tasks",
                    ),
                    const SizedBox(width: 16),
                    _bannerStat(
                      Icons.timer_outlined,
                      _fmtMinutes(d.quizMinutes),
                    ),
                    const SizedBox(width: 16),
                    _bannerStat(Icons.star_outline, "${d.totalMarks} marks"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!d.isOfficial) ...[
            OutlinedButton.icon(
              onPressed: _downloading ? null : _downloadPaper,
              icon: _downloading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
              label: Text(
                _downloading ? 'Preparing PDF...' : 'Download for Offline Use',
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!d.isOfficial) ...[
            _sectionCard(
              title: "Marking Scheme",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _markingRow(
                    Colors.green,
                    "+${d.marksPerCorrect.toStringAsFixed(d.marksPerCorrect % 1 == 0 ? 0 : 2)} for correct",
                  ),
                  _markingRow(
                    Colors.redAccent,
                    d.marksPenaltyPerWrong > 0
                        ? "-${d.marksPenaltyPerWrong.toStringAsFixed(d.marksPenaltyPerWrong % 1 == 0 ? 0 : 2)} for incorrect"
                        : "0 for incorrect",
                  ),
                  _markingRow(Colors.grey, "0 for unanswered"),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Subject breakdown
          _sectionCard(
            title: d.isOfficial ? "Section Breakdown" : "Subject Breakdown",
            child: Column(
              children: d.subjectBreakdown.map((s) {
                final color =
                    _subjectColors[s.subject] ?? context.inactiveColor;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.subject,
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        "${s.mcqCount} items/tasks",
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Pattern card for the exam category selected during signup.
          _sectionCard(
            title: "📊 $exam Pattern",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.subtleBorderColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Time Allotted",
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hms(d.quizMinutes),
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.inactiveColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Total items/tasks",
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${d.totalQuestions}",
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Subject Weightage",
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: d.subjectBreakdown.map((s) {
                      return Expanded(
                        flex: (s.weightPercent * 10).round().clamp(1, 1000),
                        child: Container(
                          height: 8,
                          color:
                              _subjectColors[s.subject] ??
                              context.subtleBorderColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            "Subject",
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            "Weight",
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            "Items",
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...d.subjectBreakdown.map(
                      (s) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              s.subject,
                              style: TextStyle(
                                color: context.primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              "${s.weightPercent.toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: context.primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              "${s.mcqCount}",
                              style: TextStyle(
                                color: context.primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          _sectionCard(
            title: "Instructions",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: d.instructions
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "• $line",
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _hms(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00";
  }

  Widget _bannerStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _markingRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: context.primaryTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
