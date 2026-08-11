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
  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  bool get _isBlack => _bg == Colors.black;

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
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 1180 || size.height < 780;
    return Scaffold(
      backgroundColor: _bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _isLight
                ? const [Color(0xFFEAF5FF), Color(0xFFF5F9FF), Colors.white]
                : (_isBlack
                      ? const [Colors.black, Colors.black, Colors.black]
                      : const [
                          Color(0xFF08264B),
                          Color(0xFF04152A),
                          Color(0xFF020B18),
                        ]),
            stops: [0, .54, 1],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(flex: 54, child: _desktopBrandPanel(compact: compact)),
              Expanded(
                flex: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _isLight
                          ? const [Color(0xFFF5F9FF), Colors.white]
                          : (_isBlack
                                ? const [Colors.black, Colors.black]
                                : const [Color(0xFF04152A), Color(0xFF020B18)]),
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 28,
                        compact ? 18 : 28,
                        compact ? 24 : 48,
                        compact ? 18 : 28,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 650),
                        child: _desktopFormCard(compact: compact),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopBrandPanel({required bool compact}) => Container(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(.05, .08),
        radius: 1.12,
        colors: _isLight
            ? const [Color(0xFFDDEEFF), Color(0xFFF8FBFF)]
            : (_isBlack
                  ? const [Colors.black, Colors.black]
                  : const [Color(0xFF092B57), Color(0xFF020B18)]),
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      compact ? 32 : 62,
      compact ? 24 : 42,
      compact ? 26 : 50,
      compact ? 24 : 38,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 48 : 54,
              height: compact ? 48 : 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_cyan, Color(0xFF4D9CFF), Color(0xFF9458F6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x4420D5C5), blurRadius: 18),
                ],
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 13),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: compact ? 27 : 30,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: 'Brain',
                    style: TextStyle(color: _text),
                  ),
                  TextSpan(
                    text: 'Boost',
                    style: TextStyle(color: _cyan),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Text.rich(
          TextSpan(
            style: TextStyle(color: _muted, fontSize: 17),
            children: const [
              TextSpan(text: 'Prepare '),
              TextSpan(
                text: 'Smarter.',
                style: TextStyle(color: _cyan),
              ),
              TextSpan(text: ' Achieve '),
              TextSpan(
                text: 'More.',
                style: TextStyle(color: Color(0xFFA05CF5)),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 22 : 34),
        Text(
          'Start Strong. Go Further.',
          style: TextStyle(
            color: _text,
            fontSize: compact ? 34 : 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'Create one account for practice, mock tests, progress insights, and guided exam preparation.',
          style: TextStyle(
            color: _muted,
            fontSize: compact ? 14 : 17,
            height: 1.5,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        Expanded(
          child: Center(
            child: Transform.scale(
              scale: compact ? 1.18 : 1.28,
              child: AnimatedHeroImage(
                asset: 'assets/images/login_hero_reference.webp',
                height: compact ? 250 : 335,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
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

  Widget _desktopFormCard({required bool compact}) => Container(
    padding: EdgeInsets.fromLTRB(
      compact ? 28 : 38,
      compact ? 24 : 30,
      compact ? 28 : 38,
      compact ? 22 : 26,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isLight
            ? const [Colors.white, Color(0xFFF4F8FF)]
            : (_isBlack
                  ? const [Colors.black, Colors.black]
                  : const [Color(0xFF101D34), Color(0xFF0B1428)]),
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFF42627D)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3320D5C5),
          blurRadius: 48,
          offset: Offset(0, 18),
        ),
        BoxShadow(
          color: Color(0x229A54F7),
          blurRadius: 36,
          offset: Offset(16, 0),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: compact ? 62 : 70,
              height: compact ? 62 : 70,
              padding: const EdgeInsets.all(1.4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_cyan, Color(0xFF9257F5)]),
                boxShadow: [
                  BoxShadow(color: Color(0x443F9CFF), blurRadius: 22),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surface,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Color(0xFF8A62F6),
                  size: 34,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            'Create your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: compact ? 29 : 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your BrainBoost preparation journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _usernameField(dark: !_isLight)),
              const SizedBox(width: 14),
              Expanded(child: _phoneField(dark: !_isLight)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _genderField(dark: !_isLight)),
              const SizedBox(width: 14),
              Expanded(child: _examField(dark: !_isLight)),
            ],
          ),
          const SizedBox(height: 14),
          _emailField(dark: !_isLight),
          const SizedBox(height: 14),
          _passwordField(dark: !_isLight),
          const SizedBox(height: 22),
          _createAccountButton(),
          const SizedBox(height: 10),
          _signInButton(dark: !_isLight),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, color: _cyan, size: 17),
              const SizedBox(width: 7),
              Text(
                'Your information is securely protected',
                style: TextStyle(color: _muted, fontSize: 12),
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
    style: dark ? TextStyle(color: _text) : null,
    decoration: _fieldDecoration('Username', Icons.person_outline, dark: dark),
    validator: (value) =>
        value == null || value.length < 3 ? 'At least 3 characters' : null,
  );

  Widget _phoneField({bool dark = false}) => TextFormField(
    controller: _phoneController,
    style: dark ? TextStyle(color: _text) : null,
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
    dropdownColor: _surface,
    style: TextStyle(color: _text),
    decoration: _fieldDecoration('Gender', Icons.people_outline, dark: dark),
    items: const ['Male', 'Female', 'Other', 'Prefer not to say']
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) => setState(() => _gender = value!),
  );

  Widget _examField({bool dark = false}) => DropdownButtonFormField<String>(
    initialValue: _targetExam,
    dropdownColor: _surface,
    style: TextStyle(color: _text),
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
    style: dark ? TextStyle(color: _text) : null,
    decoration: _fieldDecoration('Email', Icons.mail_outline, dark: dark),
    keyboardType: TextInputType.emailAddress,
    validator: (value) =>
        value == null || !value.contains('@') ? 'Enter a valid email' : null,
  );

  Widget _passwordField({bool dark = false}) => TextFormField(
    controller: _passwordController,
    style: dark ? TextStyle(color: _text) : null,
    decoration: _fieldDecoration('Password', Icons.lock_outline, dark: dark)
        .copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _muted,
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
        style: TextStyle(color: _muted, fontSize: 15),
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
      hintStyle: TextStyle(color: _muted),
      prefixIcon: Icon(icon, color: _cyan),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.subtleBorderColor),
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
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _RegisterScreenState._cyan, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
