import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_hero_image.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

const _desktopBreakpoint = 900.0;
const _cyan = Color(0xFF20D5C5);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _adminMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Login failed')));
    }
  }

  void _showAdminLogin() {
    setState(() => _adminMode = true);
    _usernameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _desktopBreakpoint) {
          return _desktopLayout();
        }
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
            Expanded(flex: 56, child: _desktopBrandPanel()),
            Expanded(
              flex: 44,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: _desktopLoginCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.1),
          radius: 1.05,
          colors: [Color(0xFF07315A), Color(0xFF020B18)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _ConstellationBackground()),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 34, 48, 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrainBoostLogo(),
                const Spacer(),
                const Center(
                  child: AnimatedHeroImage(
                    asset: 'assets/images/login_knowledge.webp',
                    height: 340,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Prepare Smarter. Achieve More.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'One platform for every exam journey.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.62),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 26),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FeatureChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Personalized Practice',
                    ),
                    _FeatureChip(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Mock Tests',
                    ),
                    _FeatureChip(
                      icon: Icons.bar_chart_rounded,
                      label: 'Progress Insights',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopLoginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(44, 42, 44, 34),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1728),
        borderRadius: BorderRadius.circular(28),
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
            Text(
              _adminMode ? 'Admin sign in' : 'Welcome back',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _adminMode
                  ? 'Access the BrainBoost administration portal'
                  : 'Continue your preparation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.58),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 34),
            _fieldLabel('Email or username'),
            const SizedBox(height: 9),
            TextFormField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              style: const TextStyle(color: Colors.white),
              decoration: _desktopInputDecoration(
                hint: 'Email or username',
                icon: Icons.person_outline_rounded,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your email or username'
                  : null,
            ),
            const SizedBox(height: 22),
            _fieldLabel('Password'),
            const SizedBox(height: 9),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              onFieldSubmitted: (_) {
                if (!_loading) _submit();
              },
              decoration:
                  _desktopInputDecoration(
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: _cyan,
                  side: const BorderSide(color: Colors.white38),
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? true),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _openForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: const Color(0xFF03131D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _adminMode ? 'Admin Sign In' : 'Sign In',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'or',
                    style: TextStyle(color: Colors.white.withOpacity(.48)),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _adminMode
                    ? () => setState(() => _adminMode = false)
                    : _showAdminLogin,
                icon: Icon(
                  _adminMode
                      ? Icons.school_outlined
                      : Icons.admin_panel_settings_outlined,
                ),
                label: Text(_adminMode ? 'Student Login' : 'Admin Login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cyan,
                  side: const BorderSide(color: _cyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New to BrainBoost? ',
                  style: TextStyle(color: Colors.white60),
                ),
                TextButton(
                  onPressed: _openRegister,
                  child: const Text('Create account'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: _cyan, size: 18),
                SizedBox(width: 7),
                Text(
                  'Your account is protected',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AnimatedHeroImage(
                    asset: 'assets/images/login_knowledge.webp',
                    height: 220,
                  ),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Continue your preparation',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Email or username',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your username'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    onFieldSubmitted: (_) {
                      if (!_loading) _submit();
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const Divider(height: 24),
                  TextButton(
                    onPressed: _openRegister,
                    child: const Text('New here? Create Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
  );

  InputDecoration _desktopInputDecoration({
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: Icon(icon, color: Colors.white54),
    filled: true,
    fillColor: const Color(0xFF071426),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF52627A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _cyan, width: 1.5),
    ),
  );

  void _openForgotPassword() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));

  void _openRegister() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
}

class _BrainBoostLogo extends StatelessWidget {
  const _BrainBoostLogo();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
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
  );
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xAA09182A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF36506E)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _cyan, size: 21),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ConstellationBackground extends StatelessWidget {
  const _ConstellationBackground();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ConstellationPainter());
}

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0x5535A8FF);
    final linePaint = Paint()
      ..color = const Color(0x2220D5C5)
      ..strokeWidth = 1;
    final points = <Offset>[
      Offset(size.width * .08, size.height * .2),
      Offset(size.width * .22, size.height * .13),
      Offset(size.width * .36, size.height * .26),
      Offset(size.width * .52, size.height * .12),
      Offset(size.width * .69, size.height * .24),
      Offset(size.width * .83, size.height * .15),
      Offset(size.width * .92, size.height * .31),
    ];
    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(point, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
