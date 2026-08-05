import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import 'past_paper_detail_screen.dart';
import '../practice/practice_by_topic_screen.dart';
import '../practice/mock_test_screen.dart';
import '../quiz/quiz_screen.dart';

const _bg = Color(0xFF0E1B26);
const _cardBg = Color(0xFF16232F);

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
    final exam = context.watch<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text("$exam Tests"),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1D9E75),
          labelColor: const Color(0xFF1D9E75),
          unselectedLabelColor: Colors.white54,
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
    final exam = context.watch<AuthProvider>().currentUser?.targetExam ?? "your exam";
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Generate fresh AI quizzes — needs an internet connection.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        _linkCard(
          context,
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF378ADD),
          title: "Practice by Topic",
          subtitle: "$exam topic-wise questions across the complete syllabus",
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PracticeByTopicScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.assignment_rounded,
          color: const Color(0xFFE0A429),
          title: "Full Mock Test",
          subtitle: "Full-length $exam test covering all selected subjects",
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MockTestScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _linkCard(
          context,
          icon: Icons.local_fire_department,
          color: const Color(0xFFE0A429),
          title: "Daily Challenge",
          subtitle: "10 $exam questions • 15 min • All subjects",
          onTap: () => Navigator.of(context).push(
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
          color: _cardBg,
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
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizScreen(quizSet: quizSet)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't open quiz: $e")));
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
            Text("Couldn't load saved quizzes: $_error",
                style: const TextStyle(color: Colors.white70)),
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
              Icon(Icons.offline_bolt_outlined, size: 56, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              const Text(
                "No saved quizzes yet",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Generate a quiz from Online Quizzes or Past Papers first — "
                "it'll show up here so you can retake it anytime without "
                "generating a new one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
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
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.offline_bolt, color: Color(0xFF1D9E75)),
              ),
              title: Text(s.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                "${s.questionCount} MCQs  •  ${s.difficulty}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: _opening
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.white38),
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
            Text("Couldn't load past papers: $_error",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text("Retry")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _papers.length,
        itemBuilder: (context, index) {
          final paper = _papers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF378ADD).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: Color(0xFF378ADD)),
              ),
              title: Text(paper.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                "${paper.totalQuestions} MCQs  •  ${_fmtMinutes(paper.quizMinutes)}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
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
}
