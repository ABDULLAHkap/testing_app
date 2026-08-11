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

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: .02,
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
                        _navButton('Contact', _contactKey, compact: compact),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 4),
      child: TextButton(
        onPressed: () => _scrollTo(key),
        style: TextButton.styleFrom(
          foregroundColor: _navy,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 13,
            vertical: 20,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w700,
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
                Expanded(
                  flex: 11,
                  child: _heroPreview(),
                ),
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
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: features
                .map((feature) => _FeatureCard(data: feature, width: cardWidth))
                .toList(),
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
              const Expanded(
                flex: 10,
                child: _ExamCloud(),
              ),
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
                    onPressed: () => _scrollTo(_homeKey),
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
        boxShadow: const [
          BoxShadow(color: Color(0x2607193D), blurRadius: 24),
        ],
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
                    color: exam == 'and more' ? const Color(0xFF74E7DD) : Colors.white,
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
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
