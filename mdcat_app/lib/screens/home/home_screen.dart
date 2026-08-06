import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../../widgets/exam_countdown_card.dart';
import '../../widgets/animated_hero_image.dart';
import '../auth/login_screen.dart';
import '../admin/admin_screen.dart';
import '../admin/communications_screen.dart';
import '../communications/announcements_screen.dart';
import '../practice/practice_by_topic_screen.dart';
import '../practice/mock_test_screen.dart';
import '../settings/server_settings_screen.dart';
import '../progress/progress_screen.dart';
import '../tests/tests_screen.dart';

const _bg = Color(0xFF0E1B26);
const _cardBg = Color(0xFF16232F);

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
                _topBar(),
                const SizedBox(height: 12),
                AnimatedHeroImage(
                  asset: 'assets/images/dashboard_knowledge.webp',
                  height: 145,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(height: 16),
                ExamCountdownCard(
                  username: username,
                  examDate: _stats?.examDate,
                  onSetDate: _pickExamDate,
                  examName: auth.currentUser?.targetExam ?? 'Exam',
                ),
                const SizedBox(height: 14),
                _dailyChallengeCard(),
                const SizedBox(height: 14),
                _statsRow(),
                const SizedBox(height: 14),
                _actionCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF378ADD),
                  iconBg: const Color(0xFF378ADD).withOpacity(0.18),
                  title: "Practice by Topic",
                  subtitle: "MCQs for ${auth.currentUser?.targetExam ?? 'your exam'} subjects",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PracticeByTopicScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionCard(
                  icon: Icons.assignment_rounded,
                  iconColor: const Color(0xFFE0A429),
                  iconBg: const Color(0xFFE0A429).withOpacity(0.18),
                  title: "Full Mock Test",
                  subtitle: "Full-length test mixing your selected exam subjects",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MockTestScreen()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar() {
    final streak = _stats?.streakDays ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: Color(0xFFE0A429), size: 20),
            const SizedBox(width: 6),
            Text("$streak day${streak == 1 ? '' : 's'}",
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        Row(
          children: [
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
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
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
    final color = active ? const Color(0xFF1D9E75) : Colors.white38;
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
