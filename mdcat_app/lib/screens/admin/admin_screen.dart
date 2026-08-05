import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getAdminOverview(),
        _api.getAdminUsers(),
      ]);
      _overview = results[0] as Map<String, dynamic>;
      _users = results[1] as List<Map<String, dynamic>>;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _stat('Users', _overview?['users']),
                      _stat('Verified', _overview?['verified_users']),
                      _stat('Tests', _overview?['completed_tests']),
                      _stat('Payments', _overview?['successful_payments']),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ..._users.map((user) => Card(
                        child: ListTile(
                          title: Text('${user['username']} • ${user['target_exam']}'),
                          subtitle: Text('${user['email']}\nFree tests: ${user['free_tests_remaining']}'),
                          isThreeLine: true,
                          trailing: user['is_admin'] == true
                              ? const Chip(label: Text('Admin'))
                              : IconButton(
                                  tooltip: 'Give 30 days',
                                  icon: const Icon(Icons.workspace_premium),
                                  onPressed: () async {
                                    await _api.grantSubscription(user['id']);
                                    await _load();
                                  },
                                ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, dynamic value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [Text('$value', style: const TextStyle(fontSize: 24)), Text(label)]),
        ),
      );
}
