import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';

const _bg = Color(0xFF061320);
const _surface = Color(0xFF10253A);
const _field = Color(0xFF0D2034);
const _cyan = Color(0xFF20D5C5);
const _purple = Color(0xFF7C5CFF);
const _text = Color(0xFFF5FAFF);
const _muted = Color(0xFFAABBD0);
const _border = Color(0xFF31516F);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = ApiClient();

  bool _codeSent = false;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _message('A reset code has been sent to your email.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _message('Password reset successfully. Please log in.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _loading = true);
    try {
      await _api.requestPasswordReset(_emailController.text.trim());
      if (mounted) _message('A new reset code has been sent.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final description = _codeSent
        ? 'Enter the 6-digit code from your email, then choose a strong new password.'
        : 'Enter your registered email and we will send a secure reset code.';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x5520D5C5), blurRadius: 28, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_cyan, _purple]),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(_codeSent ? Icons.password_rounded : Icons.lock_reset_rounded, color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _codeSent ? 'Create a new password' : 'Forgot your password?',
                        style: const TextStyle(color: _text, fontSize: 25, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(color: _muted, height: 1.45)),
                      const SizedBox(height: 24),
                      _field(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return email.contains('@') && email.contains('.')
                              ? null
                              : 'Enter a valid email address';
                        },
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 14),
                        _field(
                          controller: _codeController,
                          label: '6-digit reset code',
                          icon: Icons.password_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 6,
                          validator: (value) => (value ?? '').length == 6
                              ? null
                              : 'Enter the 6-digit code',
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _passwordController,
                          label: 'New password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hidePassword,
                          suffix: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted),
                          ),
                          validator: (value) => (value ?? '').length >= 8
                              ? null
                              : 'Use at least 8 characters',
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _confirmController,
                          label: 'Confirm new password',
                          icon: Icons.verified_user_outlined,
                          obscure: _hideConfirmation,
                          suffix: IconButton(
                            onPressed: () => setState(() => _hideConfirmation = !_hideConfirmation),
                            icon: Icon(_hideConfirmation ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted),
                          ),
                          validator: (value) => value == _passwordController.text
                              ? null
                              : 'Passwords do not match',
                        ),
                      ],
                      const SizedBox(height: 24),
                      _primaryButton(
                        label: _codeSent ? 'Reset password' : 'Send reset code',
                        icon: _codeSent ? Icons.verified_rounded : Icons.send_rounded,
                        onPressed: _loading ? null : (_codeSent ? _resetPassword : _requestCode),
                      ),
                      if (_codeSent)
                        TextButton(
                          onPressed: _loading ? null : _resendCode,
                          child: const Text('Resend code', style: TextStyle(color: _cyan, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool enabled = true,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      cursorColor: _cyan,
      style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        floatingLabelStyle: const TextStyle(color: _cyan),
        prefixIcon: Icon(icon, color: _cyan),
        suffixIcon: suffix,
        counterText: maxLength == null ? null : '',
        filled: true,
        fillColor: _field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _cyan, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_cyan, _purple]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
