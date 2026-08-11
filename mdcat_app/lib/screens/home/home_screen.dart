import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../../widgets/exam_countdown_card.dart';
import '../../utils/exam_content.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_screen.dart';
import '../admin/communications_screen.dart';
import '../communications/announcements_screen.dart';
import '../practice/practice_by_topic_screen.dart';
import '../practice/mock_test_screen.dart';
import '../practice/exam_format_screen.dart';
import '../settings/server_settings_screen.dart';
import '../progress/progress_screen.dart';
import '../tests/tests_screen.dart';
import '../tutor/tutor_chat_screen.dart';

const _cyan = Color(0xFF20D5C5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();
  DashboardStats? _stats;
  bool _loading = true;
  int _unreadAnnouncements = 0;
  String? _adminExamCategory;

  Color get _bg => context.pageBackground;
  Color get _cardBg => context.panelColor;
  Color get _text => context.primaryTextColor;
  Color get _muted => context.secondaryTextColor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _api.getDashboard();
      final unread = await _api.getUnreadAnnouncementCount();
      setState(() {
        _stats = stats;
        _unreadAnnouncements = unread;
      });
      if (stats.examDate == null && mounted) {
        // First-time student: prompt to set their exam date.
        WidgetsBinding.instance.addPostFrameCallback((_) => _pickExamDate());
      }
    } catch (_) {
      // Non-fatal — dashboard just shows defaults if this fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: "Select your exam date",
    );
    if (picked == null) return;
    try {
      await _api.setExamDate(picked);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't save date: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.currentUser?.username ?? "";
    final selectedExam = auth.currentUser?.isAdmin == true
        ? (_adminExamCategory ?? auth.currentUser?.targetExam ?? 'MDCAT')
        : (auth.currentUser?.targetExam ?? 'Exam');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return _desktopScaffold(
            username: username,
            selectedExam: selectedExam,
            isAdmin: auth.currentUser?.isAdmin == true,
          );
        }
        return _mobileScaffold(
          username: username,
          selectedExam: selectedExam,
          isAdmin: auth.currentUser?.isAdmin == true,
        );
      },
    );
  }

  Widget _mobileScaffold({
    required String username,
    required String selectedExam,
    required bool isAdmin,
  }) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeHeader(username),
              const SizedBox(height: 16),
              _categoryCard(selectedExam, isAdmin),
              const SizedBox(height: 16),
              _heroBanner(),
              const SizedBox(height: 16),
              ExamCountdownCard(
                username: username,
                examDate: _stats?.examDate,
                onSetDate: _pickExamDate,
                examName: selectedExam,
              ),
              const SizedBox(height: 14),
              _featureCards(selectedExam),
              if (!isAdmin) ...[
                const SizedBox(height: 12),
                _mobilePastPapersShortcut(selectedExam),
              ],
              const SizedBox(height: 16),
              _performanceCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: _bottomNav(),
  );

  Widget _desktopScaffold({
    required String username,
    required String selectedExam,
    required bool isAdmin,
  }) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: Row(
        children: [
          _desktopSidebar(isAdmin),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _desktopHeader(username, selectedExam, isAdmin),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _desktopHeroBanner(),
                              const SizedBox(height: 18),
                              _featureCards(selectedExam),
                              const SizedBox(height: 18),
                              _desktopPerformanceCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 330,
                          child: Column(
                            children: [
                              ExamCountdownCard(
                                username: username,
                                examDate: _stats?.examDate,
                                onSetDate: _pickExamDate,
                                examName: selectedExam,
                              ),
                              const SizedBox(height: 16),
                              _desktopRecentResultsCard(),
                              const SizedBox(height: 16),
                              _desktopStudyPlanCard(selectedExam),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _desktopSidebar(bool isAdmin) => Container(
    width: 240,
    padding: const EdgeInsets.fromLTRB(14, 28, 14, 22),
    decoration: BoxDecoration(
      color: _cardBg,
      border: Border(right: BorderSide(color: context.subtleBorderColor)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined, color: _cyan, size: 36),
              const SizedBox(width: 8),
              Text(
                'Brain',
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Boost',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        _desktopNavItem(Icons.home_rounded, 'Home', () {}, active: true),
        _desktopNavItem(
          Icons.description_outlined,
          'Tests',
          () => _openScreen(const TestsScreen()),
        ),
        _desktopNavItem(
          Icons.query_stats_rounded,
          isAdmin ? 'Admin Dashboard' : 'Progress',
          () => _openScreen(
            isAdmin ? const AdminScreen() : const ProgressScreen(),
          ),
        ),
        if (!isAdmin)
          _desktopNavItem(
            Icons.school_outlined,
            'Tutor',
            () => _openScreen(const TutorChatScreen()),
          ),
        _desktopNavItem(
          Icons.menu_book_outlined,
          isAdmin ? 'Communicate' : 'Past Papers',
          () => _openScreen(
            isAdmin
                ? const AdminCommunicationsScreen()
                : const PastPapersScreen(),
          ),
        ),
        _desktopNavItem(
          Icons.notifications_none_rounded,
          'Notifications',
          () => _openAnnouncements(),
          badge: _unreadAnnouncements,
        ),
        _desktopNavItem(
          Icons.settings_outlined,
          'Settings',
          () => _openScreen(const ServerSettingsScreen()),
        ),
        const Spacer(),
        Divider(color: context.subtleBorderColor),
        _desktopNavItem(
          Icons.logout_rounded,
          'Logout',
          _logout,
          color: const Color(0xFFFF5B64),
        ),
      ],
    ),
  );

  Widget _desktopNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
    int badge = 0,
    Color? color,
  }) {
    final foreground = color ?? (active ? _text : _muted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? _cyan.withOpacity(.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          hoverColor: _cyan.withOpacity(.09),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: active ? _cyan : foreground, size: 22),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _cyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopHeader(String username, String exam, bool isAdmin) => Row(
    children: [
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Welcome back, '),
              TextSpan(
                text: username.isEmpty ? 'Student' : username,
                style: const TextStyle(color: _cyan),
              ),
            ],
          ),
          style: TextStyle(
            color: _text,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      SizedBox(width: 220, child: _categoryCard(exam, isAdmin)),
      const SizedBox(width: 18),
      IconButton(
        tooltip: 'Notifications',
        onPressed: _openAnnouncements,
        icon: Badge(
          isLabelVisible: _unreadAnnouncements > 0,
          label: Text('$_unreadAnnouncements'),
          child: Icon(Icons.notifications_none_rounded, color: _text),
        ),
      ),
      const SizedBox(width: 8),
      Tooltip(
        message: 'Open Settings',
        child: InkWell(
          onTap: () => _openScreen(const ServerSettingsScreen()),
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            backgroundColor: _cyan.withOpacity(.18),
            foregroundColor: _cyan,
            child: Text(
              username.isEmpty ? 'S' : username[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _desktopHeroBanner() => _heroBanner(height: 310);

  Widget _desktopPerformanceCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.subtleBorderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            SizedBox(width: 240, child: _statsRow()),
            const SizedBox(width: 22),
            Expanded(
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _ProgressChartPainter(
                    gridColor: context.subtleBorderColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _desktopRecentResultsCard() => _desktopSideCard(
    title: 'Recent Results',
    child: Column(
      children: [
        _summaryMetric(
          Icons.assignment_turned_in_outlined,
          'Tests completed',
          '${_stats?.testsDone ?? 0}',
          _cyan,
        ),
        _summaryMetric(
          Icons.show_chart_rounded,
          'Average score',
          '${_stats?.avgScore.toStringAsFixed(0) ?? '0'}%',
          const Color(0xFF45A8FF),
        ),
        _summaryMetric(
          Icons.emoji_events_outlined,
          'Best score',
          '${_stats?.bestScore.toStringAsFixed(0) ?? '0'}%',
          const Color(0xFFE0A429),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _openScreen(const ProgressScreen()),
            child: const Text('View progress →'),
          ),
        ),
      ],
    ),
  );

  Widget _desktopStudyPlanCard(String exam) => _desktopSideCard(
    title: 'Study Plan',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryMetric(
          Icons.calendar_month_outlined,
          "Today's goal",
          'Complete 2 topics',
          _cyan,
        ),
        _summaryMetric(
          Icons.school_outlined,
          'Selected exam',
          exam,
          const Color(0xFF45A8FF),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _openScreen(PracticeByTopicScreen(examType: exam)),
            child: const Text('Start practicing →'),
          ),
        ),
      ],
    ),
  );

  Widget _desktopSideCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: context.subtleBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _summaryMetric(
    IconData icon,
    String label,
    String value,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(.13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: _text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _openScreen(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _openAnnouncements() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
    if (mounted) _load();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _welcomeHeader(String username) {
    final streak = _stats?.streakDays ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isEmpty ? 'Welcome back' : 'Welcome back, $username',
                style: TextStyle(
                  color: _text,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your exam journey',
                style: TextStyle(color: _muted, fontSize: 15),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0A429).withOpacity(.09),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE0A429).withOpacity(.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFE0A429),
                    size: 19,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$streak Day Streak',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Badge(
                isLabelVisible: _unreadAnnouncements > 0,
                label: Text('$_unreadAnnouncements'),
                child: Icon(Icons.notifications_none, color: _muted),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnnouncementsScreen(),
                  ),
                );
                if (mounted) _load();
              },
            ),
            IconButton(
              tooltip: 'Logout',
              icon: Icon(Icons.logout_rounded, color: _muted),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryCard(String exam, bool isAdmin) => InkWell(
    onTap: isAdmin ? () => _selectAdminCategory(exam) : null,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _cyan.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _cyan.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_outlined, color: _cyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Admin Test Category' : 'Selected Category',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                Text(
                  exam,
                  style: TextStyle(color: _text, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (isAdmin) const Icon(Icons.expand_more, color: _cyan),
        ],
      ),
    ),
  );

  Future<void> _selectAdminCategory(String current) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardBg,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Choose test category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Admin testing is unlimited and requires no subscription.',
              ),
            ),
            ...examSubjects.keys.map(
              (exam) => ListTile(
                title: Text(exam),
                trailing: exam == current
                    ? const Icon(Icons.check_circle, color: _cyan)
                    : null,
                onTap: () => Navigator.pop(context, exam),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _adminExamCategory = selected);
    }
  }

  Widget _heroBanner({double height = 190}) => SizedBox(
    height: height,
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/images/dashboard_knowledge.webp',
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, .48, 1],
                colors: [
                  Color(0xF2061320),
                  Color(0x99061320),
                  Color(0x11061320),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 22,
          top: 58,
          child: Text(
            'Stay Consistent,\nAchieve Excellence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _featureCards(String exam) {
    void openSections() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExamFormatScreen(examType: exam)));
    return Row(
      children: [
        Expanded(
          child: _featureCard(
            Icons.track_changes_rounded,
            _cyan,
            'Daily Quiz',
            '10 curated $exam questions',
            () => _dailyChallenge(exam),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureCard(
            Icons.menu_book_rounded,
            const Color(0xFF45A8FF),
            exam == 'IELTS' || exam == 'PMS' || exam == 'SAT'
                ? 'Practice Sections'
                : 'Practice by Topic',
            exam == 'IELTS' || exam == 'PMS' || exam == 'SAT'
                ? 'Use the real skill modes'
                : 'Strengthen your concepts',
            exam == 'IELTS' || exam == 'PMS' || exam == 'SAT'
                ? openSections
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PracticeByTopicScreen(examType: exam),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureCard(
            Icons.assignment_turned_in_outlined,
            const Color(0xFFE0A429),
            'Mock Test',
            '$exam objective practice',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MockTestScreen(examType: exam)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobilePastPapersShortcut(String exam) => InkWell(
    onTap: () => _openScreen(const PastPapersScreen()),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7C5CFF).withOpacity(.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CFF).withOpacity(.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: Color(0xFF7C5CFF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$exam Past Papers',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Browse and download past papers',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C5CFF)),
        ],
      ),
    ),
  );

  void _dailyChallenge(String exam) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MockTestScreen(
        presetTotalQuestions: 10,
        presetMinutes: 15,
        title: 'Daily Quiz',
        examType: exam,
      ),
    ),
  );

  Widget _featureCard(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Icon(Icons.arrow_forward_rounded, color: color),
        ],
      ),
    ),
  );

  Widget _performanceCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.subtleBorderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _statsRow(),
      ],
    ),
  );

  Widget _dailyChallengeCard() {
    final exam = context.read<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return _actionCard(
      icon: Icons.local_fire_department,
      iconColor: const Color(0xFFE0A429),
      iconBg: const Color(0xFFE0A429).withOpacity(0.18),
      title: "Daily Challenge",
      subtitle: "10 $exam questions • 15 min • All subjects",
      trailing: Icon(Icons.chevron_right, color: context.inactiveColor),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MockTestScreen(
            presetTotalQuestions: 10,
            presetMinutes: 15,
            title: "Daily Challenge",
          ),
        ),
      ),
      border: Border.all(color: const Color(0xFFE0A429).withOpacity(0.3)),
    );
  }

  Widget _statsRow() {
    final stats = _stats;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                _statItem(
                  Icons.check_circle,
                  const Color(0xFF1D9E75),
                  "${stats?.testsDone ?? 0}",
                  "Tests Done",
                ),
                _divider(),
                _statItem(
                  Icons.trending_up,
                  const Color(0xFFE0A429),
                  "${stats?.avgScore.toStringAsFixed(0) ?? 0}%",
                  "Avg Score",
                ),
                _divider(),
                _statItem(
                  Icons.emoji_events,
                  const Color(0xFF1D9E75),
                  "${stats?.bestScore.toStringAsFixed(0) ?? 0}%",
                  "Best Score",
                ),
              ],
            ),
    );
  }

  Widget _divider() =>
      Container(width: 0.5, height: 40, color: context.subtleBorderColor);

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Border? border,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward,
                  color: context.inactiveColor,
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          top: BorderSide(color: context.subtleBorderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", active: true, onTap: () {}),
          if (isAdmin)
            _navItem(
              Icons.admin_panel_settings,
              "Admin",
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
            )
          else
            _navItem(
              Icons.query_stats,
              "Progress",
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
            ),
          if (isAdmin)
            _navItem(
              Icons.campaign_outlined,
              "Communicate",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminCommunicationsScreen(),
                ),
              ),
            )
          else
            _navItem(
              Icons.description_outlined,
              "Tests",
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TestsScreen())),
            ),
          if (!isAdmin)
            _navItem(
              Icons.school_outlined,
              "Tutor",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TutorChatScreen()),
              ),
            ),
          _navItem(
            Icons.settings_outlined,
            "Settings",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? _cyan : context.inactiveColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.gridColor});

  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final values = <double>[.34, .47, .43, .62, .76, .68, .82];
    final line = Path();
    final fill = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height * (1 - values[index]);
      if (index == 0) {
        line.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x6620D5C5), Color(0x0020D5C5)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = _cyan
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height * (1 - values[index]);
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = _cyan);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
