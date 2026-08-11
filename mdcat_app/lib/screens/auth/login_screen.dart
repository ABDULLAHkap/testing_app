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
    final compact = MediaQuery.sizeOf(context).width < 1180;
    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(flex: 54, child: _desktopBrandPanel()),
            Expanded(
              flex: 46,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 24 : 48,
                    vertical: compact ? 20 : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: _desktopLoginCard(compact: compact),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640 || constraints.maxHeight < 780;
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.05, .1),
              radius: 1.1,
              colors: [Color(0xFF092B57), Color(0xFF020B18)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _ConstellationBackground()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 32 : 62,
                  compact ? 24 : 42,
                  compact ? 26 : 50,
                  compact ? 24 : 38,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrainBoostLogo(),
                    SizedBox(height: compact ? 8 : 12),
                    const _BrandTagline(),
                    SizedBox(height: compact ? 24 : 42),
                    Text(
                      'Your journey to\nsuccess starts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 35 : 46,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Text(
                      'Smart preparation, expert resources, and personalized\n'
                      'practice to help you crack every exam with confidence.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.68),
                        fontSize: compact ? 14 : 17,
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    Expanded(
                      child: Center(
                        child: AnimatedHeroImage(
                          asset: 'assets/images/login_knowledge.webp',
                          height: compact ? 250 : 330,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    const Row(
                      children: [
                        Expanded(
                          child: _BrandStat(
                            icon: Icons.menu_book_outlined,
                            value: '10,000+',
                            label: 'Expert Curated\nResources',
                            color: _cyan,
                          ),
                        ),
                        _StatDivider(),
                        Expanded(
                          child: _BrandStat(
                            icon: Icons.assignment_turned_in_outlined,
                            value: '1M+',
                            label: 'Practice Questions\nSolved',
                            color: Color(0xFFA05CF5),
                          ),
                        ),
                        _StatDivider(),
                        Expanded(
                          child: _BrandStat(
                            icon: Icons.people_outline_rounded,
                            value: '500K+',
                            label: 'Successful\nAspirants',
                            color: Color(0xFF58A6FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopLoginCard({required bool compact}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 30 : 44,
        compact ? 26 : 32,
        compact ? 30 : 44,
        compact ? 24 : 28,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101D34), Color(0xFF0B1428)],
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
                width: compact ? 66 : 76,
                height: compact ? 66 : 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_cyan, Color(0xFF9257F5)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x443F9CFF), blurRadius: 22),
                  ],
                ),
                padding: const EdgeInsets.all(1.4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF111D35),
                  ),
                  child: Icon(
                    _adminMode
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline_rounded,
                    color: const Color(0xFF8A62F6),
                    size: compact ? 34 : 40,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              _adminMode ? 'Admin Login' : 'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 30 : 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _adminMode
                  ? 'Access the BrainBoost administration portal'
                  : 'Sign in to continue your learning journey',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.58),
                fontSize: 16,
              ),
            ),
            SizedBox(height: compact ? 22 : 30),
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
            SizedBox(height: compact ? 16 : 20),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cyan, Color(0xFF4C9CFF), Color(0xFF9A54F7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x334C9CFF), blurRadius: 20),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _submit,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _adminMode ? 'Admin Sign In' : 'Sign In',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 54,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cyan, Color(0xFF9257F5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: const Color(0xFF0B172B),
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: _adminMode
                      ? () => setState(() => _adminMode = false)
                      : _showAdminLogin,
                  borderRadius: BorderRadius.circular(11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _adminMode
                            ? Icons.school_outlined
                            : Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _adminMode ? 'Student Login' : 'Admin Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 6),
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 54,
        height: 54,
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
      const Text(
        'Brain',
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Text(
        'Boost',
        style: TextStyle(
          color: _cyan,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _BrandTagline extends StatelessWidget {
  const _BrandTagline();

  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      style: TextStyle(color: Colors.white70, fontSize: 17),
      children: [
        TextSpan(text: 'Prepare '),
        TextSpan(text: 'Smarter.', style: TextStyle(color: _cyan)),
        TextSpan(text: ' Achieve '),
        TextSpan(
          text: 'More.',
          style: TextStyle(color: Color(0xFFA05CF5)),
        ),
      ],
    ),
  );
}

class _BrandStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _BrandStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(.1),
          border: Border.all(color: color.withOpacity(.75)),
        ),
        child: Icon(icon, color: color, size: 25),
      ),
      const SizedBox(width: 11),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 50,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Colors.white24,
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
