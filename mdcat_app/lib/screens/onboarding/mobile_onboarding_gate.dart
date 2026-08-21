import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shows BrainBoost's six-step introduction once on Android and iOS.
/// Web and desktop continue directly to the existing authentication gate.
class MobileOnboardingGate extends StatefulWidget {
  const MobileOnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  State<MobileOnboardingGate> createState() => _MobileOnboardingGateState();
}

class _MobileOnboardingGateState extends State<MobileOnboardingGate> {
  static const _storage = FlutterSecureStorage();
  static const _completedKey = 'mobile_onboarding_completed_v1';

  bool? _shouldShow;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) {
      if (mounted) setState(() => _shouldShow = false);
      return;
    }

    final completed = await _storage.read(key: _completedKey);
    if (mounted) setState(() => _shouldShow = completed != 'true');
  }

  Future<void> _finish() async {
    await _storage.write(key: _completedKey, value: 'true');
    if (mounted) setState(() => _shouldShow = false);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_shouldShow) {
      null => const _LaunchLoader(),
      true => MobileOnboardingScreen(onFinished: _finish),
      false => widget.child,
    };
  }
}

class _LaunchLoader extends StatelessWidget {
  const _LaunchLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class MobileOnboardingScreen extends StatefulWidget {
  const MobileOnboardingScreen({required this.onFinished, super.key});

  final Future<void> Function() onFinished;

  @override
  State<MobileOnboardingScreen> createState() =>
      _MobileOnboardingScreenState();
}

class _MobileOnboardingScreenState extends State<MobileOnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      title: 'Choose Your Exam',
      description:
          'Select your entry test so quizzes, subjects and progress match its syllabus.',
      note: 'Change category anytime in Settings.',
      type: _OnboardingVisual.exam,
    ),
    _OnboardingPageData(
      title: 'Build Your Study Plan',
      description:
          'Ask AI Tutor for a preparation plan, daily timetable and guidance based on your exam date.',
      note: 'Plans adapt to your goal.',
      type: _OnboardingVisual.plan,
    ),
    _OnboardingPageData(
      title: 'Practice Every Day',
      description:
          'Start daily quizzes or practice by topic. Questions follow your selected exam and syllabus.',
      note: 'Answer before moving Next.',
      type: _OnboardingVisual.practice,
    ),
    _OnboardingPageData(
      title: 'Test Like the Real Exam',
      description:
          'Attempt timed mock tests and practice past papers in your selected exam format.',
      note: 'Every test uses a different question set.',
      type: _OnboardingVisual.tests,
    ),
    _OnboardingPageData(
      title: 'Review and Improve',
      description:
          'See correct answers, learn from mistakes and track progress for your current exam.',
      note: 'Your dashboard shows what to study next.',
      type: _OnboardingVisual.progress,
    ),
    _OnboardingPageData(
      title: 'Start Your Preparation',
      description:
          'Use three free tests on your account, then subscribe separately to the exam categories you need.',
      note: 'Your account and progress stay protected.',
      type: _OnboardingVisual.access,
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished();
  }

  Future<void> _next() async {
    if (_isLast) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final colors = _OnboardingColors(light: light);

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.15,
            colors: [colors.glow, colors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _BrandHeader(colors: colors),
              const SizedBox(height: 4),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                    step: index + 1,
                    colors: colors,
                  ),
                ),
              ),
              _BottomNavigation(
                index: _index,
                pageCount: _pages.length,
                isLast: _isLast,
                busy: _finishing,
                colors: colors,
                onSkip: _finish,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.colors});

  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF25D9FF), Color(0xFFA05CFF)],
          ).createShader(bounds),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 31),
        ),
        const SizedBox(width: 8),
        Text(
          'BrainBoost',
          style: TextStyle(
            color: colors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.step,
    required this.colors,
  });

  final _OnboardingPageData data;
  final int step;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 570;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, compact ? 8 : 16, 22, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              children: [
                _StepLabel(step: step, colors: colors),
                SizedBox(height: compact ? 10 : 16),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: compact ? 25 : 29,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: compact ? 13 : 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: compact ? 14 : 22),
                SizedBox(
                  height: compact ? 245 : 300,
                  child: _FeatureVisual(type: data.type, colors: colors),
                ),
                SizedBox(height: compact ? 12 : 18),
                _InfoNote(text: data.note, colors: colors),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.step, required this.colors});

  final int step;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: colors.cyan.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.cyan.withValues(alpha: .7)),
      ),
      child: Text(
        'STEP $step',
        style: TextStyle(
          color: colors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text, required this.colors});

  final String text;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: colors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureVisual extends StatelessWidget {
  const _FeatureVisual({required this.type, required this.colors});

  final _OnboardingVisual type;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.cyan.withValues(alpha: .10),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: switch (type) {
        _OnboardingVisual.exam => _ExamVisual(colors: colors),
        _OnboardingVisual.plan => _PlanVisual(colors: colors),
        _OnboardingVisual.practice => _PracticeVisual(colors: colors),
        _OnboardingVisual.tests => _TestsVisual(colors: colors),
        _OnboardingVisual.progress => _ProgressVisual(colors: colors),
        _OnboardingVisual.access => _AccessVisual(colors: colors),
      },
    );
  }
}

class _ExamVisual extends StatelessWidget {
  const _ExamVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('MDCAT', Icons.medical_services_outlined),
      ('ECAT', Icons.calculate_outlined),
      ('NUST', Icons.school_outlined),
      ('CSS', Icons.account_balance_outlined),
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final selected = index == 0;
        return _FeatureCard(
          colors: colors,
          selected: selected,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[index].$2, color: selected ? colors.cyan : colors.purple, size: 32),
              const SizedBox(height: 7),
              Text(items[index].$1, style: _cardTitle(colors)),
            ],
          ),
        );
      },
    );
  }
}

class _PlanVisual extends StatelessWidget {
  const _PlanVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _GlowIcon(icon: Icons.smart_toy_outlined, colors: colors),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                colors: colors,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Study Plan', style: _cardTitle(colors)),
                      const SizedBox(height: 5),
                      Text('Built around your exam date', style: _cardBody(colors)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _FeatureCard(
            colors: colors,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _scheduleRow('08:00', 'Physics · Mechanics', colors),
                  _scheduleRow('10:00', 'Chemistry · Organic', colors),
                  _scheduleRow('14:00', 'Biology · Cell Biology', colors),
                  _scheduleRow('16:00', 'Mock Test', colors),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PracticeVisual extends StatelessWidget {
  const _PracticeVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.fact_check_outlined,
            title: 'Daily Quiz',
            subtitle: 'Unique MCQs every day',
            badge: '20 MCQs',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Topic Practice',
            subtitle: 'Choose a subject and topic',
            badge: 'By Topic',
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _TestsVisual extends StatelessWidget {
  const _TestsVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TallFeatureCard(
            icon: Icons.timer_outlined,
            title: 'Mock Tests',
            lines: const ['Timed test', 'Real format', 'Instant result'],
            colors: colors,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _TallFeatureCard(
            icon: Icons.description_outlined,
            title: 'Past Papers',
            lines: const ['Previous papers', 'Exam pattern', 'Topic practice'],
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _ProgressVisual extends StatelessWidget {
  const _ProgressVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  colors: colors,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 95,
                          height: 95,
                          child: CircularProgressIndicator(
                            value: .78,
                            strokeWidth: 9,
                            backgroundColor: colors.border,
                            color: colors.cyan,
                          ),
                        ),
                        Text('78%', style: _cardTitle(colors).copyWith(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _ScoreTile('Correct', '78', Icons.check_circle, const Color(0xFF35DB9A), colors)),
                    const SizedBox(height: 10),
                    Expanded(child: _ScoreTile('Review', '22', Icons.cancel, const Color(0xFFFF6577), colors)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _FeatureCard(
          colors: colors,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, color: colors.cyan, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text('Progress improves with every reviewed test', style: _cardBody(colors))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessVisual extends StatelessWidget {
  const _AccessVisual({required this.colors});
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 66,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.cyan, colors.purple]),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('3 FREE TESTS', style: TextStyle(color: colors.cyan, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 13),
        Expanded(
          child: _FeatureCard(
            colors: colors,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _GlowIcon(icon: Icons.verified_user_outlined, colors: colors),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secure student account', style: _cardTitle(colors)),
                        const SizedBox(height: 5),
                        Text('Separate access for every subscribed exam category', style: _cardBody(colors)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.badge, required this.colors});
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _GlowIcon(icon: icon, colors: colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _cardTitle(colors)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: _cardBody(colors)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: colors.purple.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
              child: Text(badge, style: TextStyle(color: colors.purple, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TallFeatureCard extends StatelessWidget {
  const _TallFeatureCard({required this.icon, required this.title, required this.lines, required this.colors});
  final IconData icon;
  final String title;
  final List<String> lines;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GlowIcon(icon: icon, colors: colors),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: _cardTitle(colors)),
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colors.cyan, size: 15),
                    const SizedBox(width: 6),
                    Expanded(child: Text(line, style: _cardBody(colors).copyWith(fontSize: 11))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.child, required this.colors, this.selected = false});
  final Widget child;
  final _OnboardingColors colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? colors.cyan : colors.border, width: selected ? 1.7 : 1),
        boxShadow: selected ? [BoxShadow(color: colors.cyan.withValues(alpha: .16), blurRadius: 18)] : null,
      ),
      child: child,
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.icon, required this.colors});
  final IconData icon;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.cyan.withValues(alpha: .23), colors.purple.withValues(alpha: .23)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cyan.withValues(alpha: .45)),
      ),
      child: Icon(icon, color: colors.cyan, size: 29),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile(this.label, this.value, this.icon, this.color, this.colors);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final _OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: _cardTitle(colors)),
                Text(label, style: _cardBody(colors).copyWith(fontSize: 10.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.index, required this.pageCount, required this.isLast, required this.busy, required this.colors, required this.onSkip, required this.onNext});
  final int index;
  final int pageCount;
  final bool isLast;
  final bool busy;
  final _OnboardingColors colors;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: TextButton(
              key: const Key('onboarding-skip'),
              onPressed: busy ? null : onSkip,
              child: Text('Skip', style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pageCount,
                (dot) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: dot == index ? 17 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dot == index ? colors.cyan : colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: isLast ? 126 : 90,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.cyan, colors.purple]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: colors.purple.withValues(alpha: .24), blurRadius: 18)],
              ),
              child: TextButton(
                key: const Key('onboarding-next'),
                onPressed: busy ? null : onNext,
                child: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isLast ? 'Get Started' : 'Next', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _scheduleRow(String time, String subject, _OnboardingColors colors) {
  return Expanded(
    child: Row(
      children: [
        SizedBox(width: 47, child: Text(time, style: TextStyle(color: colors.cyan, fontSize: 11.5, fontWeight: FontWeight.w700))),
        Container(width: 3, height: 24, decoration: BoxDecoration(color: colors.purple, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 9),
        Expanded(child: Text(subject, overflow: TextOverflow.ellipsis, style: _cardBody(colors).copyWith(fontSize: 11.5))),
      ],
    ),
  );
}

TextStyle _cardTitle(_OnboardingColors colors) => TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800);
TextStyle _cardBody(_OnboardingColors colors) => TextStyle(color: colors.muted, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500);

enum _OnboardingVisual { exam, plan, practice, tests, progress, access }

class _OnboardingPageData {
  const _OnboardingPageData({required this.title, required this.description, required this.note, required this.type});
  final String title;
  final String description;
  final String note;
  final _OnboardingVisual type;
}

class _OnboardingColors {
  _OnboardingColors({required bool light})
      : background = light ? const Color(0xFFF4F8FF) : const Color(0xFF020817),
        glow = light ? const Color(0xFFE9E6FF) : const Color(0xFF10184A),
        panel = light ? const Color(0xEEFFFFFF) : const Color(0xB30A1730),
        card = light ? const Color(0xFFF7FAFF) : const Color(0xC4122240),
        text = light ? const Color(0xFF111B36) : Colors.white,
        muted = light ? const Color(0xFF53617A) : const Color(0xFFB8C3D9),
        border = light ? const Color(0xFFD7E0F0) : const Color(0xFF30466B);

  final Color background;
  final Color glow;
  final Color panel;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color cyan = const Color(0xFF18CFF5);
  final Color purple = const Color(0xFF9257F5);
}
