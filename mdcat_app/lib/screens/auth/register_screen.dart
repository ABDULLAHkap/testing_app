import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_hero_image.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Male';
  String _targetExam = 'MDCAT';
  static const _exams = [
    'MDCAT',
    'ECAT',
    'NUST NET',
    'NTS',
    'CSS',
    'LAT',
    'IELTS',
    'PMS',
    'SAT',
    'General Knowledge',
  ];
  bool _loading = false;
  bool _obscurePassword = true;

  static const _cyan = Color(0xFF20D5C5);

  Color get _bg => context.pageBackground;
  Color get _surface => context.panelColor;
  Color get _text => context.primaryTextColor;
  Color get _muted => context.secondaryTextColor;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _gender,
      _phoneController.text.trim(),
      _targetExam,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              VerifyEmailScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) return _desktopLayout();
        return _mobileLayout();
      },
    );
  }

  Widget _desktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(flex: 50, child: _desktopBrandPanel()),
            Expanded(
              flex: 50,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 42,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _desktopFormCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopBrandPanel() => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.1),
        radius: 1.05,
        colors: [Color(0xFF07315A), Color(0xFF020B18)],
      ),
    ),
    padding: const EdgeInsets.fromLTRB(54, 34, 46, 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.psychology_outlined, color: _cyan, size: 42),
            SizedBox(width: 10),
            Text(
              'Brain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Boost',
              style: TextStyle(
                color: _cyan,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        const Center(
          child: AnimatedHeroImage(
            asset: 'assets/images/signup_knowledge.webp',
            height: 380,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Start Strong. Go Further.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Create one account for practice, mock tests, progress insights, and guided exam preparation.',
          style: TextStyle(
            color: Colors.white.withOpacity(.62),
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SignupBenefit(
              icon: Icons.check_circle_outline,
              text: '3 free tests',
            ),
            _SignupBenefit(icon: Icons.school_outlined, text: 'Multiple exams'),
            _SignupBenefit(
              icon: Icons.insights_outlined,
              text: 'Track progress',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _desktopFormCard() => Container(
    padding: const EdgeInsets.fromLTRB(38, 34, 38, 28),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1728),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFF41516A)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4400B8D4),
          blurRadius: 42,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start your BrainBoost preparation journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _usernameField(dark: true)),
              const SizedBox(width: 14),
              Expanded(child: _phoneField(dark: true)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _genderField(dark: true)),
              const SizedBox(width: 14),
              Expanded(child: _examField(dark: true)),
            ],
          ),
          const SizedBox(height: 14),
          _emailField(dark: true),
          const SizedBox(height: 14),
          _passwordField(dark: true),
          const SizedBox(height: 22),
          _createAccountButton(),
          const SizedBox(height: 10),
          _signInButton(dark: true),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: _cyan, size: 17),
              SizedBox(width: 7),
              Text(
                'Your information is securely protected',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _mobileLayout() => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AnimatedHeroImage(
                  asset: 'assets/images/signup_knowledge.webp',
                  height: 245,
                ),
                const SizedBox(height: 18),
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: _text,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your preparation',
                  style: TextStyle(color: _muted, fontSize: 17),
                ),
                const SizedBox(height: 24),
                _usernameField(),
                const SizedBox(height: 14),
                _phoneField(),
                const SizedBox(height: 14),
                _genderField(),
                const SizedBox(height: 14),
                _examField(),
                const SizedBox(height: 14),
                _emailField(),
                const SizedBox(height: 14),
                _passwordField(),
                const SizedBox(height: 22),
                _createAccountButton(),
                const SizedBox(height: 10),
                _signInButton(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _usernameField({bool dark = false}) => TextFormField(
    controller: _usernameController,
    style: dark ? const TextStyle(color: Colors.white) : null,
    decoration: _fieldDecoration('Username', Icons.person_outline, dark: dark),
    validator: (value) =>
        value == null || value.length < 3 ? 'At least 3 characters' : null,
  );

  Widget _phoneField({bool dark = false}) => TextFormField(
    controller: _phoneController,
    style: dark ? const TextStyle(color: Colors.white) : null,
    decoration: _fieldDecoration(
      'Phone number',
      Icons.phone_android_outlined,
      dark: dark,
    ).copyWith(counterText: ''),
    keyboardType: TextInputType.phone,
    maxLength: 11,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (value) => value == null || !RegExp(r'^\d{11}$').hasMatch(value)
        ? 'Phone number must contain exactly 11 digits'
        : null,
  );

  Widget _genderField({bool dark = false}) => DropdownButtonFormField<String>(
    initialValue: _gender,
    dropdownColor: dark ? const Color(0xFF0A1728) : _surface,
    style: TextStyle(color: dark ? Colors.white : _text),
    decoration: _fieldDecoration('Gender', Icons.people_outline, dark: dark),
    items: const ['Male', 'Female', 'Other', 'Prefer not to say']
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) => setState(() => _gender = value!),
  );

  Widget _examField({bool dark = false}) => DropdownButtonFormField<String>(
    initialValue: _targetExam,
    dropdownColor: dark ? const Color(0xFF0A1728) : _surface,
    style: TextStyle(color: dark ? Colors.white : _text),
    decoration: _fieldDecoration(
      'Test category',
      Icons.grid_view_rounded,
      dark: dark,
    ),
    items: _exams
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) => setState(() => _targetExam = value!),
  );

  Widget _emailField({bool dark = false}) => TextFormField(
    controller: _emailController,
    style: dark ? const TextStyle(color: Colors.white) : null,
    decoration: _fieldDecoration('Email', Icons.mail_outline, dark: dark),
    keyboardType: TextInputType.emailAddress,
    validator: (value) =>
        value == null || !value.contains('@') ? 'Enter a valid email' : null,
  );

  Widget _passwordField({bool dark = false}) => TextFormField(
    controller: _passwordController,
    style: dark ? const TextStyle(color: Colors.white) : null,
    decoration: _fieldDecoration('Password', Icons.lock_outline, dark: dark)
        .copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: dark ? Colors.white54 : _muted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
    obscureText: _obscurePassword,
    onFieldSubmitted: (_) {
      if (!_loading) _submit();
    },
    validator: (value) =>
        value == null || value.length < 6 ? 'At least 6 characters' : null,
  );

  Widget _createAccountButton() => SizedBox(
    height: 58,
    child: ElevatedButton(
      onPressed: _loading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _cyan,
        foregroundColor: const Color(0xFF031018),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Create Account',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    ),
  );

  Widget _signInButton({bool dark = false}) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: Text.rich(
      TextSpan(
        style: TextStyle(color: dark ? Colors.white54 : _muted, fontSize: 15),
        children: const [
          TextSpan(text: 'Already registered? '),
          TextSpan(
            text: 'Sign In',
            style: TextStyle(color: _cyan, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  InputDecoration _fieldDecoration(
    String hint,
    IconData icon, {
    bool dark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: dark ? Colors.white38 : _muted),
      prefixIcon: Icon(icon, color: _cyan),
      filled: true,
      fillColor: dark ? const Color(0xFF071426) : _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF52627A) : context.subtleBorderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cyan, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _SignupBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SignupBenefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xAA09182A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF36506E)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _RegisterScreenState._cyan, size: 20),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}
