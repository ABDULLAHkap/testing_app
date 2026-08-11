import 'package:flutter/material.dart';

import '../../widgets/animated_hero_image.dart';
import 'login_screen.dart';

const _blue = Color(0xFF1575EA);
const _navy = Color(0xFF071A3D);
const _cyan = Color(0xFF19CBBB);

/// Public BrainBoost introduction shown only on desktop-sized signed-out views.
/// All navigation remains on this page; the two calls to action open login.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _contactKey = GlobalKey();
  String _activeNav = 'Home';
  String? _hoveredNav;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveNavigation);
  }

  void _syncActiveNavigation() {
    if (!mounted) return;
    final sections = <(String, GlobalKey)>[
      ('Home', _homeKey),
      ('Features', _featuresKey),
      ('How It Works', _howItWorksKey),
      ('About', _aboutKey),
      ('Contact', _contactKey),
    ];
    var nearest = 'Home';
    for (final section in sections) {
      final sectionContext = section.$2.currentContext;
      if (sectionContext == null) continue;
      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box != null && box.localToGlobal(Offset.zero).dy <= 150) {
        nearest = section.$1;
      }
    }
    if (nearest != _activeNav) setState(() => _activeNav = nearest);
  }

  void _scrollTo(String label, GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    setState(() => _activeNav = label);
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: .02,
    );
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: Column(
        children: [
          _topNavigation(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _heroSection(),
                  _featuresSection(),
                  _howItWorksSection(),
                  _aboutSection(),
                  _contactSection(),
                  _footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topNavigation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The navigation content is constrained to 1320 px below.  Use the
        // compact spacing on common laptop and 1440 px displays as well so
        // every destination and both auth actions remain visible.
        final compact = constraints.maxWidth < 1500;
        return Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x1907193D),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 76,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 14 : 28,
                    ),
                    child: Row(
                      children: [
                        _LandingLogo(compact: compact),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F6FD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDCE7F7)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D071A3D),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _navButton('Home', _homeKey, compact: compact),
                              _navButton(
                                'Features',
                                _featuresKey,
                                compact: compact,
                              ),
                              _navButton(
                                'How It Works',
                                _howItWorksKey,
                                compact: compact,
                              ),
                              _navButton('About', _aboutKey, compact: compact),
                              _navButton(
                                'Contact',
                                _contactKey,
                                compact: compact,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 24),
                        OutlinedButton(
                          onPressed: _openLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            side: const BorderSide(color: _blue),
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 28,
                              vertical: 17,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _openLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 28,
                              vertical: 17,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navButton(String label, GlobalKey key, {required bool compact}) {
    final active = _activeNav == label;
    final hovered = _hoveredNav == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredNav = label),
      onExit: (_) {
        if (_hoveredNav == label) setState(() => _hoveredNav = null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF1575EA), Color(0xFF19CBBB)],
                )
              : null,
          color: !active && hovered ? Colors.white : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x331575EA),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _scrollTo(label, key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 15,
                vertical: 11,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : _navy,
                  fontSize: compact ? 12 : 14,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: active ? .1 : 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroSection() {
    return Container(
      key: _homeKey,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDF7FF), Colors.white],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 74, 56, 70),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow(label: 'YOUR COMPLETE EXAM COMPANION'),
                      const SizedBox(height: 24),
                      const Text(
                        'Prepare Smarter,\nScore Better',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 60,
                          height: 1.02,
                          letterSpacing: -2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SizedBox(
                        width: 550,
                        child: Text(
                          'Prepare for MDCAT, ECAT, NUST NET, IELTS, CSS, PMS, '
                          'LAT, NTS and more with focused practice, mock tests, '
                          'past papers and clear progress insights.',
                          style: TextStyle(
                            color: Color(0xFF53627A),
                            fontSize: 19,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _openLogin,
                            icon: const Icon(Icons.rocket_launch_outlined),
                            label: const Text('Get Started'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 20,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton.icon(
                            onPressed: _openLogin,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: const BorderSide(color: _blue),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 20,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Wrap(
                        spacing: 26,
                        runSpacing: 12,
                        children: [
                          _TrustItem(
                            icon: Icons.verified_user_outlined,
                            label: 'Secure accounts',
                          ),
                          _TrustItem(
                            icon: Icons.fact_check_outlined,
                            label: 'Exam focused',
                          ),
                          _TrustItem(
                            icon: Icons.devices_outlined,
                            label: 'Learn on any device',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 34),
                Expanded(flex: 11, child: _heroPreview()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroPreview() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 470,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF061A39), Color(0xFF0D3564)],
            ),
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28235FA4),
                blurRadius: 48,
                offset: Offset(0, 22),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _WindowDot(color: Color(0xFFFF6B6B)),
                  _WindowDot(color: Color(0xFFFFC857)),
                  _WindowDot(color: Color(0xFF38D996)),
                  Spacer(),
                  Text(
                    'BrainBoost learning workspace',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: AnimatedHeroImage(
                  asset: 'assets/images/login_hero_reference.webp',
                  height: 390,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: -26,
          top: 92,
          child: _FloatingMetric(
            icon: Icons.insights_rounded,
            title: 'Progress',
            value: 'Track every attempt',
            color: _cyan,
          ),
        ),
        const Positioned(
          right: -20,
          bottom: 52,
          child: _FloatingMetric(
            icon: Icons.auto_awesome_outlined,
            title: 'Smart practice',
            value: 'Focus on weak topics',
            color: Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _featuresSection() {
    const features = [
      _FeatureData(
        Icons.checklist_rounded,
        'Practice by Topic',
        'Build strong concepts with focused questions for the exam category you select.',
        Color(0xFF14B88F),
      ),
      _FeatureData(
        Icons.assignment_turned_in_outlined,
        'Mock Tests',
        'Simulate exam conditions with timed tests, category-specific formats and result review.',
        Color(0xFF8B5CF6),
      ),
      _FeatureData(
        Icons.description_outlined,
        'Past Papers',
        'Find exam resources by year, subject, source and board in one organized library.',
        Color(0xFFF59E42),
      ),
      _FeatureData(
        Icons.query_stats_rounded,
        'Progress Insights',
        'See scores, completed tests, weak topics and improvement across your preparation.',
        Color(0xFF2686E9),
      ),
    ];

    return _section(
      key: _featuresKey,
      eyebrow: 'FEATURES',
      title: 'Everything you need to prepare with confidence',
      subtitle:
          'One focused workspace for daily learning, test practice and measurable improvement.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 54) / 4;
          return Column(
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: features
                    .map(
                      (feature) =>
                          _FeatureCard(data: feature, width: cardWidth),
                    )
                    .toList(),
              ),
              const SizedBox(height: 72),
              _DashboardPhoneShowcase(wide: constraints.maxWidth >= 1080),
            ],
          );
        },
      ),
    );
  }

  Widget _howItWorksSection() {
    return Container(
      key: _howItWorksKey,
      width: double.infinity,
      color: const Color(0xFFF0F7FF),
      padding: const EdgeInsets.symmetric(vertical: 86, horizontal: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Column(
            children: [
              const _Eyebrow(label: 'HOW IT WORKS'),
              const SizedBox(height: 15),
              const Text(
                'Start learning in three simple steps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 50),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StepCard(
                      number: '1',
                      icon: Icons.grid_view_rounded,
                      title: 'Choose your exam',
                      description:
                          'Select the category you want to prepare for when creating your account.',
                    ),
                  ),
                  _StepConnector(),
                  Expanded(
                    child: _StepCard(
                      number: '2',
                      icon: Icons.edit_note_rounded,
                      title: 'Practice and test',
                      description:
                          'Use daily quizzes, focused practice, past papers and full mock tests.',
                    ),
                  ),
                  _StepConnector(),
                  Expanded(
                    child: _StepCard(
                      number: '3',
                      icon: Icons.trending_up_rounded,
                      title: 'Review and improve',
                      description:
                          'Check answers, understand mistakes and use insights to improve weak areas.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              FilledButton.icon(
                onPressed: _openLogin,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Start your preparation'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutSection() {
    return Container(
      key: _aboutKey,
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 52),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow(
                      label: 'ABOUT BRAINBOOST',
                      color: Color(0xFF73E2D7),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'One platform for many exam journeys',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1.14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'BrainBoost helps students organize preparation, practice '
                      'consistently and understand results. Each account is '
                      'personalized around the student’s selected exam category.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 18,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 70),
              const Expanded(flex: 10, child: _ExamCloud()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactSection() {
    return Container(
      key: _contactKey,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 82, horizontal: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 48),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDF7FF), Color(0xFFF5F1FF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD9E8F8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 28),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need help or want to report a problem?',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Our administrators can help with account, subscription and test-related questions.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContactEmail(email: 'm.abdullah.aac@gmail.com'),
                    SizedBox(height: 12),
                    _ContactEmail(email: 'choudrymnouman@gmail.com'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF041431),
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 16,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  const _LandingLogo(light: true),
                  Text(
                    'Prepare smarter. Improve with every attempt.',
                    style: TextStyle(color: Colors.white.withOpacity(.62)),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 26,
                children: [
                  TextButton(
                    onPressed: () => _scrollTo('Home', _homeKey),
                    child: const Text('Back to top'),
                  ),
                  Text(
                    '© 2026 BrainBoost',
                    style: TextStyle(color: Colors.white.withOpacity(.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required GlobalKey key,
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 86, horizontal: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Column(
            children: [
              _Eyebrow(label: eyebrow),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 45),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingLogo extends StatelessWidget {
  final bool light;
  final bool compact;

  const _LandingLogo({this.light = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 46,
          height: compact ? 38 : 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cyan, Color(0xFF5F7EF7), Color(0xFF9B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
        ),
        SizedBox(width: compact ? 8 : 11),
        Text(
          'Brain',
          style: TextStyle(
            color: light ? Colors.white : _navy,
            fontSize: compact ? 21 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        Text(
          'Boost',
          style: TextStyle(
            color: _cyan,
            fontSize: compact ? 21 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String label;
  final Color color;

  const _Eyebrow({required this.label, this.color = _blue});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  final Color color;

  const _WindowDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 7),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _cyan, size: 20),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF53627A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FloatingMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _FloatingMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x2607193D), blurRadius: 24)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureData(this.icon, this.title, this.description, this.color);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  final double width;

  const _FeatureCard({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 244),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EAF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1207193D),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 29),
          ),
          const SizedBox(height: 20),
          Text(
            data.title,
            style: const TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            data.description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPhoneShowcase extends StatelessWidget {
  final bool wide;

  const _DashboardPhoneShowcase({required this.wide});

  @override
  Widget build(BuildContext context) {
    const leftBenefits = [
      _ShowcaseBenefitData(
        Icons.dashboard_customize_outlined,
        'One focused dashboard',
        'See your selected exam, countdown and next learning activity at a glance.',
        _cyan,
      ),
      _ShowcaseBenefitData(
        Icons.track_changes_rounded,
        'Daily exam practice',
        'Build a steady routine with Daily Challenge and topic-wise preparation.',
        Color(0xFF2686E9),
      ),
    ];
    const rightBenefits = [
      _ShowcaseBenefitData(
        Icons.fact_check_outlined,
        'Real test preparation',
        'Open full mock tests and category-specific practice from the same screen.',
        Color(0xFF8B5CF6),
      ),
      _ShowcaseBenefitData(
        Icons.insights_rounded,
        'Progress that stays clear',
        'Review completed tests, average score and best performance as you improve.',
        Color(0xFFF59E42),
      ),
    ];

    final heading = Column(
      children: [
        const _Eyebrow(label: 'DASHBOARD PREVIEW', color: _cyan),
        const SizedBox(height: 12),
        const Text(
          'Your complete preparation journey, in one place',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A realistic look at the BrainBoost mobile dashboard students use every day.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(.68),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );

    Widget benefitColumn(List<_ShowcaseBenefitData> benefits) {
      return Column(
        children: [
          for (var index = 0; index < benefits.length; index++) ...[
            _ShowcaseBenefit(data: benefits[index]),
            if (index != benefits.length - 1) const SizedBox(height: 22),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(wide ? 42 : 24, 42, wide ? 42 : 24, 48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06172F), Color(0xFF0A2A4D), Color(0xFF071A3D)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0A4A7A),
            blurRadius: 50,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -80,
            top: -90,
            child: _ShowcaseGlow(color: Color(0x4019CBBB), size: 260),
          ),
          const Positioned(
            left: -90,
            bottom: 30,
            child: _ShowcaseGlow(color: Color(0x308B5CF6), size: 240),
          ),
          Column(
            children: [
              heading,
              const SizedBox(height: 42),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: benefitColumn(leftBenefits)),
                    const SizedBox(width: 34),
                    const _DashboardPhonePreview(),
                    const SizedBox(width: 34),
                    Expanded(child: benefitColumn(rightBenefits)),
                  ],
                )
              else ...[
                const _DashboardPhonePreview(),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final benefit in [...leftBenefits, ...rightBenefits])
                      SizedBox(
                        width: 320,
                        child: _ShowcaseBenefit(data: benefit),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcaseGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _ShowcaseGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _ShowcaseBenefitData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ShowcaseBenefitData(
    this.icon,
    this.title,
    this.description,
    this.color,
  );
}

class _ShowcaseBenefit extends StatelessWidget {
  final _ShowcaseBenefitData data;

  const _ShowcaseBenefit({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: data.color.withOpacity(.35)),
            ),
            child: Icon(data.icon, color: data.color, size: 25),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(
              color: Colors.white.withOpacity(.64),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPhonePreview extends StatelessWidget {
  const _DashboardPhonePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 326,
      height: 650,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF020712),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF52647A), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x6619CBBB), blurRadius: 34),
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: const Color(0xFF071A2A),
          child: Stack(
            children: [
              const Positioned(
                right: -70,
                top: 50,
                child: _ShowcaseGlow(color: Color(0x3519CBBB), size: 180),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
                child: Column(
                  children: [
                    const _PhoneStatusBar(),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Continue your exam journey',
                                style: TextStyle(
                                  color: Color(0xFF93A7B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PhoneIconButton(
                          icon: Icons.notifications_none_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _PhoneExamSelector(),
                    const SizedBox(height: 13),
                    const _PhoneHeroCard(),
                    const SizedBox(height: 13),
                    const _PhoneCountdown(),
                    const SizedBox(height: 13),
                    const Row(
                      children: [
                        Expanded(
                          child: _PhoneActionCard(
                            icon: Icons.local_fire_department_rounded,
                            title: 'Daily',
                            color: Color(0xFFFFB84D),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _PhoneActionCard(
                            icon: Icons.menu_book_rounded,
                            title: 'Topics',
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _PhoneActionCard(
                            icon: Icons.fact_check_rounded,
                            title: 'Mock test',
                            color: Color(0xFFB77BFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    const _PhoneProgressCard(),
                    const Spacer(),
                    const _PhoneBottomNavigation(),
                  ],
                ),
              ),
              Positioned(
                top: 7,
                left: 110,
                right: 110,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF020712),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Spacer(),
        Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 12),
        SizedBox(width: 4),
        Icon(Icons.wifi_rounded, color: Colors.white, size: 12),
        SizedBox(width: 4),
        Icon(Icons.battery_full_rounded, color: Colors.white, size: 13),
      ],
    );
  }
}

class _PhoneIconButton extends StatelessWidget {
  final IconData icon;

  const _PhoneIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _PhoneExamSelector extends StatelessWidget {
  const _PhoneExamSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2733),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x6640E0CE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.grid_view_rounded, color: _cyan, size: 17),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Selected exam  •  MDCAT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: _cyan, size: 18),
        ],
      ),
    );
  }
}

class _PhoneHeroCard extends StatelessWidget {
  const _PhoneHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C5756), Color(0xFF102E55)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0x5540E0CE)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Stay consistent,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'achieve excellence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your next goal is ready',
                  style: TextStyle(color: Color(0xFFB4CCCF), fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x3319CBBB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xAA19CBBB)),
              boxShadow: const [
                BoxShadow(color: Color(0x6619CBBB), blurRadius: 18),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF6AF1E3),
              size: 37,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneCountdown extends StatelessWidget {
  const _PhoneCountdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: _cyan, size: 23),
          SizedBox(width: 9),
          Text(
            'Exam starts in',
            style: TextStyle(color: Color(0xFFB8C7D5), fontSize: 10),
          ),
          Spacer(),
          _PhoneTimeValue(value: '24', label: 'DAYS'),
          _PhoneTimeValue(value: '08', label: 'HRS'),
          _PhoneTimeValue(value: '47', label: 'MIN'),
        ],
      ),
    );
  }
}

class _PhoneTimeValue extends StatelessWidget {
  final String value;
  final String label;

  const _PhoneTimeValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      margin: const EdgeInsets.only(left: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _cyan,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8397A8), fontSize: 6),
          ),
        ],
      ),
    );
  }
}

class _PhoneActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _PhoneActionCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.09)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneProgressCard extends StatelessWidget {
  const _PhoneProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.09)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          Row(
            children: [
              _PhoneStat(value: '18', label: 'Tests'),
              _PhoneStat(value: '72%', label: 'Average'),
              _PhoneStat(value: '88%', label: 'Best'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneStat extends StatelessWidget {
  final String value;
  final String label;

  const _PhoneStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _cyan,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8397A8), fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _PhoneBottomNavigation extends StatelessWidget {
  const _PhoneBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2232),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PhoneNavItem(icon: Icons.home_rounded, active: true),
          _PhoneNavItem(icon: Icons.insights_rounded),
          _PhoneNavItem(icon: Icons.description_outlined),
          _PhoneNavItem(icon: Icons.settings_outlined),
        ],
      ),
    );
  }
}

class _PhoneNavItem extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _PhoneNavItem({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0x2219CBBB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: active ? _cyan : const Color(0xFF718594),
        size: 18,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x1F146BE8), blurRadius: 28),
                ],
              ),
              child: Icon(icon, color: _blue, size: 42),
            ),
            Positioned(
              top: -7,
              right: -5,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 82,
      height: 96,
      child: Center(
        child: Icon(Icons.arrow_forward_rounded, color: _blue, size: 30),
      ),
    );
  }
}

class _ExamCloud extends StatelessWidget {
  const _ExamCloud();

  @override
  Widget build(BuildContext context) {
    const exams = [
      'MDCAT',
      'ECAT',
      'NUST NET',
      'IELTS',
      'CSS',
      'PMS',
      'LAT',
      'NTS',
      'and more',
    ];
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(.13)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: exams
            .map(
              (exam) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: exam == 'and more'
                      ? _cyan.withOpacity(.16)
                      : Colors.white.withOpacity(.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: exam == 'and more'
                        ? _cyan.withOpacity(.5)
                        : Colors.white.withOpacity(.15),
                  ),
                ),
                child: Text(
                  exam,
                  style: TextStyle(
                    color: exam == 'and more'
                        ? const Color(0xFF74E7DD)
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ContactEmail extends StatelessWidget {
  final String email;

  const _ContactEmail({required this.email});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.email_outlined, color: _blue, size: 21),
        const SizedBox(width: 9),
        SelectableText(
          email,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
