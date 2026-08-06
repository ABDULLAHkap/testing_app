import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../../widgets/exam_countdown_card.dart';
import '../../widgets/animated_hero_image.dart';
import '../admin/admin_screen.dart';
import '../admin/communications_screen.dart';
import '../communications/announcements_screen.dart';
import '../practice/practice_by_topic_screen.dart';
import '../practice/mock_test_screen.dart';
import '../settings/server_settings_screen.dart';
import '../progress/progress_screen.dart';
import '../tests/tests_screen.dart';

const _bg = Color(0xFF061320);
const _cardBg = Color(0xFF101F32);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't save date: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.currentUser?.username ?? "";

    return Scaffold(
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
                _categoryCard(auth.currentUser?.targetExam ?? 'Exam'),
                const SizedBox(height: 16),
                _heroBanner(),
                const SizedBox(height: 16),
                ExamCountdownCard(
                  username: username,
                  examDate: _stats?.examDate,
                  onSetDate: _pickExamDate,
                  examName: auth.currentUser?.targetExam ?? 'Exam',
                ),
                const SizedBox(height: 14),
                _featureCards(),
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
              Text(username.isEmpty ? 'Welcome back' : 'Welcome back, $username',
                  style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              const Text('Your exam journey', style: TextStyle(color: Colors.white54, fontSize: 15)),
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
                border: Border.all(color: const Color(0xFFE0A429).withOpacity(.35)),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department, color: Color(0xFFE0A429), size: 19),
                const SizedBox(width: 5),
                Text('$streak Day Streak', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Badge(
                isLabelVisible: _unreadAnnouncements > 0,
                label: Text('$_unreadAnnouncements'),
                child: const Icon(Icons.notifications_none, color: Colors.white70),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                );
                if (mounted) _load();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryCard(String exam) => Container(
    width: 220,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _cyan.withOpacity(.35)),
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _cyan.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.school_outlined, color: _cyan)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Selected Category', style: TextStyle(color: Colors.white54, fontSize: 11)),
        Text(exam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );

  Widget _heroBanner() => Stack(
    children: [
      AnimatedHeroImage(asset: 'assets/images/dashboard_knowledge.webp', height: 190, fit: BoxFit.cover, borderRadius: BorderRadius.circular(22)),
      Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xE8061320), Color(0x22061320), Colors.transparent])))),
      const Positioned(left: 22, top: 58, child: Text('Stay Consistent,\nAchieve Excellence', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700, height: 1.15))),
    ],
  );

  Widget _featureCards() => Row(children: [
    Expanded(child: _featureCard(Icons.track_changes_rounded, _cyan, 'Daily Challenge', 'Curated questions daily', _dailyChallenge)),
    const SizedBox(width: 10),
    Expanded(child: _featureCard(Icons.menu_book_rounded, const Color(0xFF45A8FF), 'Practice by Topic', 'Strengthen your concepts', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeByTopicScreen())))),
    const SizedBox(width: 10),
    Expanded(child: _featureCard(Icons.assignment_turned_in_outlined, const Color(0xFFE0A429), 'Full Mock Test', 'Real exam experience', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MockTestScreen())))),
  ]);

  void _dailyChallenge() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MockTestScreen(presetTotalQuestions: 10, presetMinutes: 15, title: 'Daily Challenge')));

  Widget _featureCard(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(.13), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
        const Spacer(),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(subtitle, maxLines: 2, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 12),
        Icon(Icons.arrow_forward_rounded, color: color),
      ]),
    ),
  );

  Widget _performanceCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Performance Overview', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      _statsRow(),
    ]),
  );

  Widget _dailyChallengeCard() {
    final exam = context.read<AuthProvider>().currentUser?.targetExam ?? "Exam";
    return _actionCard(
      icon: Icons.local_fire_department,
      iconColor: const Color(0xFFE0A429),
      iconBg: const Color(0xFFE0A429).withOpacity(0.18),
      title: "Daily Challenge",
      subtitle: "10 $exam questions • 15 min • All subjects",
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
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
                _statItem(Icons.check_circle, const Color(0xFF1D9E75),
                    "${stats?.testsDone ?? 0}", "Tests Done"),
                _divider(),
                _statItem(Icons.trending_up, const Color(0xFFE0A429),
                    "${stats?.avgScore.toStringAsFixed(0) ?? 0}%", "Avg Score"),
                _divider(),
                _statItem(Icons.emoji_events, const Color(0xFF1D9E75),
                    "${stats?.bestScore.toStringAsFixed(0) ?? 0}%", "Best Score"),
              ],
            ),
    );
  }

  Widget _divider() => Container(width: 0.5, height: 40, color: Colors.white12);

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
            trailing ?? const Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", active: true, onTap: () {}),
          if (isAdmin)
            _navItem(Icons.admin_panel_settings, "Admin",
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ))
          else
            _navItem(Icons.query_stats, "Progress",
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    )),
          if (isAdmin)
            _navItem(Icons.campaign_outlined, "Communicate",
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminCommunicationsScreen(),
                      ),
                    ))
          else
            _navItem(Icons.description_outlined, "Tests",
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestsScreen()),
                    )),
          _navItem(Icons.settings_outlined, "Settings",
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                  )),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool active = false, required VoidCallback onTap}) {
    final color = active ? _cyan : Colors.white38;
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
