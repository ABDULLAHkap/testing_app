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
    return Scaffold(
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
                  TextFormField(
                    controller: _usernameController,
                    decoration: _fieldDecoration(
                      'Username',
                      Icons.person_outline,
                    ),
                    validator: (v) => (v == null || v.length < 3)
                        ? "At least 3 characters"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _fieldDecoration(
                      'Phone number',
                      Icons.phone_android_outlined,
                    ).copyWith(counterText: ''),
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || !RegExp(r'^\d{11}$').hasMatch(v))
                        ? "Phone number must contain exactly 11 digits"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    dropdownColor: _surface,
                    decoration: _fieldDecoration(
                      'Gender',
                      Icons.people_outline,
                    ),
                    items:
                        const ['Male', 'Female', 'Other', 'Prefer not to say']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _targetExam,
                    dropdownColor: _surface,
                    decoration: _fieldDecoration(
                      'Test category',
                      Icons.grid_view_rounded,
                    ),
                    items: _exams
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _targetExam = value!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: _fieldDecoration('Email', Icons.mail_outline),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains("@"))
                        ? "Enter a valid email"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _fieldDecoration('Password', Icons.lock_outline)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _muted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.length < 6)
                        ? "At least 6 characters"
                        : null,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: const Color(0xFF031018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                              "Create Account",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: _muted, fontSize: 15),
                        children: const [
                          TextSpan(text: 'Already registered? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: _cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
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
