import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../admin/admin_screen.dart';

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

  // Server
  final _urlController = TextEditingController();
  bool _savingUrl = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final currentUrl = await _api.getBaseUrl();
    if (!mounted) return;
    setState(() {
      _usernameController.text = auth.currentUser?.username ?? "";
      _urlController.text = currentUrl;
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

  Future<void> _saveServerUrl() async {
    var url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }

    setState(() => _savingUrl = true);
    await _api.setBaseUrl(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Server URL saved")));
    setState(() => _savingUrl = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final signedIn = context.watch<AuthProvider>().currentUser != null;
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;

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
                  const SizedBox(height: 32),
                ],
                if (isAdmin) ...[
                  _sectionHeader("Administration"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text("Open admin dashboard"),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                _sectionHeader("Server"),
                const SizedBox(height: 8),
                const Text(
                  "Change this without rebuilding the app — useful when "
                  "testing locally and your computer's IP address changes, "
                  "or when switching to your deployed HTTPS backend.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: "Server URL",
                    hintText: "https://your-api.onrender.com",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _savingUrl ? null : _saveServerUrl,
                  child: _savingUrl
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Save Server URL"),
                ),
                const SizedBox(height: 12),
                Text(
                  "Tip: after saving, logout/login again so all screens "
                  "pick up the new URL.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
