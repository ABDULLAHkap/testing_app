import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../communications/support_chat_screen.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final ApiClient _api = ApiClient();

  // Account
  final _usernameController = TextEditingController();
  bool _savingUsername = false;
  bool _changingEmail = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    setState(() {
      _usernameController.text = auth.currentUser?.username ?? "";
      _loading = false;
    });
  }

  Future<void> _saveUsername() async {
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _savingUsername = true);
    try {
      await _api.updateUsername(newName);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Username updated")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't update username: $e")));
    } finally {
      if (mounted) setState(() => _savingUsername = false);
    }
  }

  Future<void> _changeEmail() async {
    final currentEmail = context.read<AuthProvider>().currentUser?.email ?? "";
    final newEmailController = TextEditingController();
    final newEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Change email address"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("The confirmation code will be sent to your current email: $currentEmail"),
            const SizedBox(height: 16),
            TextField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "New email address"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              newEmailController.text.trim(),
            ),
            child: const Text("Send code"),
          ),
        ],
      ),
    );
    newEmailController.dispose();
    if (newEmail == null || !newEmail.contains("@") || !mounted) return;

    setState(() => _changingEmail = true);
    try {
      await _api.requestEmailChange(newEmail);
      if (!mounted) return;
      final codeController = TextEditingController();
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Verify current email"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter the 6-digit code sent to $currentEmail."),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: "Verification code"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                codeController.text.trim(),
              ),
              child: const Text("Verify and change"),
            ),
          ],
        ),
      );
      codeController.dispose();
      if (code == null || code.length != 6) return;
      await _api.confirmEmailChange(newEmail, code);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email address changed successfully")),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not change email: $error")),
      );
    } finally {
      if (mounted) setState(() => _changingEmail = false);
    }
  }

  Future<void> _contactSupport(String email) async {
    final uri = Uri(
      scheme: "mailto",
      path: email,
      queryParameters: {
        "subject": "AI Exam Preparation - Help or Problem Report",
      },
    );
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please email $email")),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final signedIn = context.watch<AuthProvider>().currentUser != null;
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    final currentEmail = context.watch<AuthProvider>().currentUser?.email ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (signedIn) ...[
                  _sectionHeader("Account"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _savingUsername ? null : _saveUsername,
                    child: _savingUsername
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save Username"),
                  ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 20),
                    Text("Email: $currentEmail"),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _changingEmail ? null : _changeEmail,
                      icon: const Icon(Icons.alternate_email),
                      label: Text(
                        _changingEmail ? "Changing email..." : "Change Email Address",
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "For security, the verification code is sent to your current email address.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
                _sectionHeader("Appearance"),
                const SizedBox(height: 8),
                _themeOption(
                  context,
                  label: "Light",
                  icon: Icons.light_mode_outlined,
                  mode: ThemeMode.light,
                  current: themeProvider.mode,
                ),
                _themeOption(
                  context,
                  label: "Dark",
                  icon: Icons.dark_mode_outlined,
                  mode: ThemeMode.dark,
                  current: themeProvider.mode,
                ),
                _themeOption(
                  context,
                  label: "Match Device",
                  icon: Icons.smartphone,
                  mode: ThemeMode.system,
                  current: themeProvider.mode,
                ),
                const SizedBox(height: 8),
                Text(
                  "Note: this changes standard screens like Login and "
                  "Practice forms. The Dashboard, Tests, and Quiz screens "
                  "use their own fixed dark styling either way.",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                _sectionHeader("Help & Support"),
                const SizedBox(height: 8),
                const Text("For help or to report a problem, contact:"),
                if (signedIn && !isAdmin)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text("Chat with admins"),
                    subtitle: const Text(
                      "Discuss app problems or test-related questions",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SupportChatScreen(),
                      ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("m.abdullah.aac@gmail.com"),
                  subtitle: const Text("Tap to send an email"),
                  onTap: () => _contactSupport("m.abdullah.aac@gmail.com"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("choudrymnouman@gmail.com"),
                  subtitle: const Text("Tap to send an email"),
                  onTap: () => _contactSupport("choudrymnouman@gmail.com"),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode current,
  }) {
    final selected = mode == current;
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: current,
      onChanged: (value) {
        if (value != null) {
          context.read<ThemeProvider>().setMode(value);
        }
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
      selected: selected,
      contentPadding: EdgeInsets.zero,
    );
  }
}
