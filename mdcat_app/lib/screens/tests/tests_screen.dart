import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../services/file_saver.dart';
import '../../theme/app_theme.dart';
import 'past_paper_detail_screen.dart';
import '../practice/practice_by_topic_screen.dart';
import '../practice/mock_test_screen.dart';
import '../practice/adaptive_practice_screen.dart';
import '../practice/exam_format_screen.dart';
import '../quiz/quiz_screen.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam =
        context.watch<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: Text("$exam Tests"),
        backgroundColor: context.pageBackground,
        foregroundColor: context.primaryTextColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1D9E75),
          labelColor: const Color(0xFF1D9E75),
          unselectedLabelColor: context.secondaryTextColor,
          tabs: const [
            Tab(text: "Offline Quizzes"),
            Tab(text: "Online Quizzes"),
            Tab(text: "Past Papers"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OfflineQuizzesTab(),
          _OnlineQuizzesTab(),
          _PastPapersTab(),
        ],
      ),
    );
  }
}

class _OnlineQuizzesTab extends StatelessWidget {
  const _OnlineQuizzesTab();

  @override
  Widget build(BuildContext context) {
    final exam =
        context.watch<AuthProvider>().currentUser?.targetExam ?? "your exam";
    final sectionBased = exam == 'IELTS' || exam == 'PMS' || exam == 'SAT';
    void openSections() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExamFormatScreen(examType: exam)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Generate fresh quizzes — needs an internet connection.",
            style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
          ),
        ),
        _linkCard(
          context,
          icon: Icons.account_tree_outlined,
          color: const Color(0xFF7C5CFF),
          title: "Official Exam Format",
          subtitle: "Real sections, duration, question count and marking rules",
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ExamFormatScreen())),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.auto_graph,
          color: const Color(0xFF20D5C5),
          title: "Adaptive Practice",
          subtitle: "More practice for weak topics, less for mastered topics",
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdaptivePracticeScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF378ADD),
          title: sectionBased ? "Practice by Section" : "Practice by Topic",
          subtitle: sectionBased
              ? "Use each $exam skill in its real preparation mode"
              : "$exam topic-wise questions across the complete syllabus",
          onTap: sectionBased
              ? openSections
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PracticeByTopicScreen(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.assignment_rounded,
          color: const Color(0xFFE0A429),
          title: sectionBased
              ? "Section-Based Mock Practice"
              : "Full Mock Test",
          subtitle: sectionBased
              ? "Practise the official $exam sections separately"
              : "Full-length $exam test covering all selected subjects",
          onTap: sectionBased
              ? openSections
              : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockTestScreen()),
                ),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.local_fire_department,
          color: const Color(0xFFE0A429),
          title: sectionBased ? "Daily Section Practice" : "Daily Challenge",
          subtitle: sectionBased
              ? "Continue one focused $exam skill session"
              : "10 $exam questions • 15 min • All subjects",
          onTap: sectionBased
              ? openSections
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MockTestScreen(
                      presetTotalQuestions: 10,
                      presetMinutes: 15,
                      title: "Daily Challenge",
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _linkCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: context.inactiveColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OfflineQuizzesTab extends StatefulWidget {
  const _OfflineQuizzesTab();

  @override
  State<_OfflineQuizzesTab> createState() => _OfflineQuizzesTabState();
}

class _OfflineQuizzesTabState extends State<_OfflineQuizzesTab> {
  final ApiClient _api = ApiClient();
  List<QuizSetSummary> _sets = [];
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sets = await _api.listQuizSets();
      setState(() => _sets = sets);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _retake(int quizSetId) async {
    setState(() => _opening = true);
    try {
      final quizSet = await _api.getQuizSet(quizSetId);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't open quiz: $e")));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load saved quizzes: $_error",
              style: TextStyle(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_sets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_bolt_outlined,
                size: 56,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                "No saved quizzes yet",
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Generate a quiz from Online Quizzes or Past Papers first — "
                "it'll show up here so you can retake it anytime without "
                "generating a new one.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sets.length,
        itemBuilder: (context, index) {
          final s = _sets[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.offline_bolt, color: Color(0xFF1D9E75)),
              ),
              title: Text(
                s.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "${s.questionCount} MCQs  •  ${s.difficulty}",
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              trailing: _opening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.play_arrow, color: context.inactiveColor),
              onTap: _opening ? null : () => _retake(s.id),
            ),
          );
        },
      ),
    );
  }
}

class _PastPapersTab extends StatefulWidget {
  const _PastPapersTab();

  @override
  State<_PastPapersTab> createState() => _PastPapersTabState();
}

class _PastPapersTabState extends State<_PastPapersTab> {
  final ApiClient _api = ApiClient();
  List<PastPaperSummary> _papers = [];
  bool _loading = true;
  String _sourceFilter = 'all';
  int? _yearFilter;
  String? _subjectFilter;
  String? _boardFilter;
  String? _downloadingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final papers = await _api.getPastPapers();
      setState(() => _papers = papers);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return "$m min";
    if (m == 0) return "$h hr";
    return "$h hr $m min";
  }

  List<PastPaperSummary> get _filtered => _papers.where((paper) {
    final sourceMatches =
        _sourceFilter == 'all' || paper.sourceType == _sourceFilter;
    final yearMatches = _yearFilter == null || paper.year == _yearFilter;
    final subjectMatches =
        _subjectFilter == null || paper.subject == _subjectFilter;
    final boardMatches = _boardFilter == null || paper.board == _boardFilter;
    return sourceMatches && yearMatches && subjectMatches && boardMatches;
  }).toList();

  Future<void> _download(PastPaperSummary paper) async {
    setState(() => _downloadingId = paper.id);
    try {
      final bytes = await _api.downloadPastPaper(paper.id);
      await savePdf(
        bytes,
        '${paper.examType.replaceAll(' ', '_')}_Practice_${paper.year}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't download paper: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load past papers: $_error",
              style: TextStyle(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text("Retry")),
          ],
        ),
      );
    }

    final papers = _filtered;
    final years = _papers.map((paper) => paper.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final subjects = _papers.map((paper) => paper.subject).toSet().toList()
      ..sort();
    final boards = _papers.map((paper) => paper.board).toSet().toList()..sort();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: papers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DropdownButton<String>(
                    value: _sourceFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All sources'),
                      ),
                      DropdownMenuItem(
                        value: 'official',
                        child: Text('Official'),
                      ),
                      DropdownMenuItem(
                        value: 'practice',
                        child: Text('Practice'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _sourceFilter = value!),
                  ),
                  DropdownButton<int?>(
                    value: _yearFilter,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All years'),
                      ),
                      ...years.map(
                        (year) => DropdownMenuItem<int?>(
                          value: year,
                          child: Text('$year'),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _yearFilter = value),
                  ),
                  DropdownButton<String?>(
                    value: _subjectFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All subjects'),
                      ),
                      ...subjects.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _subjectFilter = value),
                  ),
                  DropdownButton<String?>(
                    value: _boardFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All boards'),
                      ),
                      ...boards.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _boardFilter = value),
                  ),
                  Chip(label: Text('${papers.length} papers/resources')),
                ],
              ),
            );
          }
          final paper = papers[index - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF378ADD).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF378ADD),
                ),
              ),
              title: Text(
                paper.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${paper.totalQuestions} questions  •  ${_fmtMinutes(paper.quizMinutes)} • ${paper.year}",
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: [
                      _paperBadge(
                        paper.isOfficial
                            ? 'OFFICIAL SOURCE'
                            : 'ORIGINAL PRACTICE',
                        paper.isOfficial
                            ? Colors.green
                            : const Color(0xFF378ADD),
                      ),
                      _paperBadge(paper.board, context.inactiveColor),
                    ],
                  ),
                ],
              ),
              trailing: paper.downloadAvailable
                  ? IconButton(
                      tooltip: 'Download for offline use',
                      onPressed: _downloadingId == null
                          ? () => _download(paper)
                          : null,
                      icon: _downloadingId == paper.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_for_offline_outlined),
                    )
                  : Icon(Icons.chevron_right, color: context.inactiveColor),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PastPaperDetailScreen(paperId: paper.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _paperBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(.13),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
    ),
  );
}
