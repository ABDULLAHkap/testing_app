import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';

const _purple = Color(0xFF7C4DFF);
const _pink = Color(0xFFFF3D9A);
const _navy = Color(0xFF111A3A);
const _muted = Color(0xFF6E7890);
const _soft = Color(0xFFF7F7FC);

class MobileAuthFlow extends StatefulWidget {
  const MobileAuthFlow({super.key});

  @override
  State<MobileAuthFlow> createState() => _MobileAuthFlowState();
}

class _MobileAuthFlowState extends State<MobileAuthFlow> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      eyebrow: 'WELCOME TO BRAINBOOST',
      title: 'Prepare smarter.\nScore higher.',
      description:
          'A focused exam-preparation workspace built for students who want simple, organized and effective practice.',
    ),
    _OnboardingData(
      icon: Icons.menu_book_rounded,
      eyebrow: 'EVERYTHING IN ONE PLACE',
      title: 'Practice that matches\nyour exam journey.',
      description:
          'Use past papers, mock tests, quizzes and focused practice without jumping between different apps.',
    ),
    _OnboardingData(
      icon: Icons.verified_user_rounded,
      eyebrow: 'STUDENT FIRST',
      title: 'Secure. Simple.\nStudent friendly.',
      description:
          'Your account is protected, navigation stays clear, and your preparation remains focused on your selected exam.',
    ),
    _OnboardingData(
      icon: Icons.workspace_premium_rounded,
      eyebrow: 'WHY STUDENTS CHOOSE BRAINBOOST',
      title: 'Build confidence\nwith every test.',
      description:
          'Track progress, review mistakes, practice past papers and start with three free tests on one account.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _openWelcome();
  }

  void _openWelcome() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MobileWelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
              child: Row(
                children: [
                  const _MiniLogo(),
                  const Spacer(),
                  TextButton(
                    onPressed: _openWelcome,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _OnboardingPage(
                  data: _pages[index],
                  page: index,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _page ? 26 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: index == _page
                              ? const LinearGradient(colors: [_purple, _pink])
                              : null,
                          color: index == _page ? null : const Color(0xFFE4E6EF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GradientButton(
                    label: _page == _pages.length - 1 ? 'Get Started' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final int page;
  const _OnboardingPage({required this.data, required this.page});

  @override
  Widget build(BuildContext context) {
    final List<Widget> featureCards = page == 1
        ? const [
            _FeaturePill(Icons.description_outlined, 'Past Papers'),
            _FeaturePill(Icons.assignment_turned_in_outlined, 'Mock Tests'),
            _FeaturePill(Icons.quiz_outlined, 'Quizzes'),
          ]
        : page == 3
            ? const [
                _FeaturePill(Icons.insights_rounded, 'Progress Tracking'),
                _FeaturePill(Icons.fact_check_outlined, 'Mistake Review'),
                _FeaturePill(Icons.card_giftcard_rounded, '3 Free Tests'),
              ]
            : const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
      child: Column(
        children: [
          Container(
            height: 285,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF211965), Color(0xFF6431B8), Color(0xFFE13E9C)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x337C4DFF),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 28,
                  right: 26,
                  child: _bubble(Icons.star_rounded, 52, .18),
                ),
                Positioned(
                  bottom: 30,
                  left: 22,
                  child: _bubble(Icons.auto_graph_rounded, 58, .14),
                ),
                Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .22)),
                    ),
                    child: Icon(data.icon, size: 74, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Text(
            data.eyebrow,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _purple,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 31,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 15.5, height: 1.55),
          ),
          if (featureCards.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              alignment: WrapAlignment.center,
              children: featureCards,
            ),
          ],
          if (page == 2) ...[
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: _TrustCard(Icons.shield_outlined, 'Secure account')),
                SizedBox(width: 10),
                Expanded(child: _TrustCard(Icons.school_outlined, 'Student friendly')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _bubble(IconData icon, double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white70),
      );
}

class MobileWelcomeScreen extends StatelessWidget {
  const MobileWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _BrandLogo(size: 64),
              const SizedBox(height: 18),
              const Text(
                'BrainBoost',
                style: TextStyle(color: _navy, fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prepare Smarter • Score Higher',
                style: TextStyle(color: _muted, fontSize: 15),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0EBFF), Color(0xFFFFEDF7)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.school_rounded, color: _purple, size: 82),
                    SizedBox(height: 14),
                    Text(
                      'Ready to start your preparation?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _navy, fontSize: 23, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose an option below to continue.',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ActionCard(
                icon: Icons.lock_open_rounded,
                title: 'Login',
                subtitle: 'Welcome back to BrainBoost',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Create Account',
                subtitle: 'Join BrainBoost and start practicing',
                pink: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MobileRegisterScreen()),
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF18A878), size: 18),
                  SizedBox(width: 7),
                  Text('Secure • Student friendly • Exam focused', style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _username.text.trim(),
      _password.text,
      rememberMe: _remember,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AuthHeader(
              icon: Icons.lock_open_rounded,
              title: 'Welcome Back!',
              subtitle: 'Login to continue your preparation',
            ),
            const SizedBox(height: 28),
            _MobileField(
              controller: _username,
              label: 'Email or username',
              icon: Icons.email_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your email or username'
                  : null,
            ),
            const SizedBox(height: 14),
            _MobileField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: _purple,
                  onChanged: (value) => setState(() => _remember = value ?? false),
                ),
                const Text('Remember me', style: TextStyle(color: _muted, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _GradientButton(
              label: 'Login',
              icon: Icons.arrow_forward_rounded,
              loading: _loading,
              onTap: _loading ? null : _submit,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('NEW TO BRAINBOOST?', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MobileRegisterScreen()),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: Color(0xFFD9DCE8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            const _SecureFooter(),
          ],
        ),
      ),
    );
  }
}

class MobileRegisterScreen extends StatefulWidget {
  const MobileRegisterScreen({super.key});

  @override
  State<MobileRegisterScreen> createState() => _MobileRegisterScreenState();
}

class _MobileRegisterScreenState extends State<MobileRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'Male';
  String _exam = 'MDCAT';
  bool _loading = false;
  bool _obscure = true;

  static const _exams = [
    'MDCAT', 'ECAT', 'NUST NET', 'NTS', 'CSS', 'LAT', 'IELTS', 'PMS', 'SAT', 'General Knowledge'
  ];

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _username.text.trim(),
      _email.text.trim(),
      _password.text,
      _gender,
      _phone.text.trim(),
      _exam,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MobileVerifyEmailScreen(email: _email.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AuthHeader(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Create Account',
              subtitle: 'Let’s get you started',
            ),
            const SizedBox(height: 18),
            const _StepBar(active: 1),
            const SizedBox(height: 22),
            _MobileField(
              controller: _username,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              validator: (value) => value == null || value.trim().length < 3 ? 'At least 3 characters' : null,
            ),
            const SizedBox(height: 12),
            _MobileField(
              controller: _email,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            _MobileField(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 11,
              validator: (value) => value == null || !RegExp(r'^\d{11}$').hasMatch(value) ? 'Phone number must contain exactly 11 digits' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _inputDecoration('Gender', Icons.person_search_outlined),
              items: const ['Male', 'Female', 'Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _gender = value ?? _gender),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _exam,
              decoration: _inputDecoration('Select exam category', Icons.school_outlined),
              items: _exams.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _exam = value ?? _exam),
            ),
            const SizedBox(height: 12),
            _MobileField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null,
            ),
            const SizedBox(height: 20),
            _GradientButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              loading: _loading,
              onTap: _loading ? null : _submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: _muted)),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
            const _SecureFooter(),
          ],
        ),
      ),
    );
  }
}

class MobileVerifyEmailScreen extends StatefulWidget {
  final String email;
  const MobileVerifyEmailScreen({super.key, required this.email});

  @override
  State<MobileVerifyEmailScreen> createState() => _MobileVerifyEmailScreenState();
}

class _MobileVerifyEmailScreenState extends State<MobileVerifyEmailScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(widget.email, _code.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified. Please login.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AuthHeader(
            icon: Icons.mark_email_read_outlined,
            title: 'Verify Your Email',
            subtitle: 'One last step to secure your account',
          ),
          const SizedBox(height: 18),
          const _StepBar(active: 2),
          const SizedBox(height: 26),
          Text(
            'We sent a 6-digit verification code to\n${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('6-digit code', Icons.password_rounded).copyWith(counterText: ''),
          ),
          const SizedBox(height: 18),
          _GradientButton(
            label: 'Verify',
            icon: Icons.verified_rounded,
            loading: _loading,
            onTap: _loading ? null : _verify,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final ok = await auth.resendOtp(widget.email);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'New code sent' : auth.lastError ?? 'Failed to resend code')),
              );
            },
            child: const Text('Resend code'),
          ),
          const SizedBox(height: 18),
          const _SecureFooter(),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  final Widget child;
  const _AuthScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _navy),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
          child: child,
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AuthHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const _MiniLogo(),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, _pink]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x337C4DFF), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 15)),
        ],
      );
}

class _MobileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _MobileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator,
        decoration: _inputDecoration(label, icon).copyWith(
          suffixIcon: suffix,
          counterText: maxLength != null ? '' : null,
        ),
      );
}

InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _purple),
      filled: true,
      fillColor: _soft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E4ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _purple, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  const _GradientButton({required this.label, required this.icon, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_purple, _pink]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x337C4DFF), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Icon(icon, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool pink;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap, this.pink = false});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: pink ? const Color(0xFFFFF0F7) : const Color(0xFFF1EEFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pink ? const Color(0xFFFFD3E8) : const Color(0xFFDED5FF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: pink ? const [_pink, Color(0xFFFF6EB1)] : const [_purple, Color(0xFF9D7BFF)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: pink ? _pink : _purple),
              ],
            ),
          ),
        ),
      );
}

class _StepBar extends StatelessWidget {
  final int active;
  const _StepBar({required this.active});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final selected = index < active;
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 16 : 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: selected ? const LinearGradient(colors: [_purple, _pink]) : null,
                  color: selected ? null : const Color(0xFFE7E8EF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (index < 2) Container(width: 46, height: 2, color: const Color(0xFFE7E8EF)),
            ],
          );
        }),
      );
}

class _SecureFooter extends StatelessWidget {
  const _SecureFooter();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF18A878)),
          SizedBox(width: 7),
          Text('Your information is securely protected', style: TextStyle(color: _muted, fontSize: 12)),
        ],
      );
}

class _MiniLogo extends StatelessWidget {
  const _MiniLogo();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandLogo(size: 38),
          SizedBox(width: 9),
          Text('Brain', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900)),
          Text('Boost', style: TextStyle(color: _purple, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      );
}

class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_purple, _pink]),
          borderRadius: BorderRadius.circular(size * .3),
        ),
        child: Icon(Icons.psychology_alt_rounded, color: Colors.white, size: size * .62),
      );
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1FF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFE4DBFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: _purple),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(color: _navy, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _TrustCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustCard(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7E8EF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _purple, size: 26),
            const SizedBox(height: 7),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );
}

class _OnboardingData {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  const _OnboardingData({required this.icon, required this.eyebrow, required this.title, required this.description});
}
