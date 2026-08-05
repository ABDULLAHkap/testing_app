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
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            child: Text('${user['username']}'.substring(0, 1).toUpperCase()),
                          ),
                          title: Text('${user['username']} • ${user['target_exam']}'),
                          subtitle: Text('${user['email']}\n${user['phone'] ?? 'No phone'}'),
                          trailing: user['is_admin'] == true
                              ? const Chip(label: Text('Admin'))
                              : const Icon(Icons.expand_more),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            _detail('Email', user['email']),
                            _detail('Phone', user['phone']),
                            _detail('Gender', user['gender']),
                            _detail('Exam category', user['target_exam']),
                            _detail('Email verified', user['email_verified'] == true ? 'Yes' : 'No'),
                            _detail('Tests completed', user['tests_done']),
                            _detail('Average score', '${user['average_score']}%'),
                            _detail('Best score', '${user['best_score']}%'),
                            _detail('Free tests remaining', user['free_tests_remaining']),
                            _detail('Exam date', user['exam_date'] ?? 'Not set'),
                            _detail('Registered', user['created_at']),
                            _detail('Last test', user['last_test_at'] ?? 'No test yet'),
                            _detail('Subscription expires', user['subscription_expires_at'] ?? 'Not subscribed'),
                            if (user['is_admin'] != true)
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.workspace_premium),
                                  label: const Text('Give 30 days'),
                                  onPressed: () async {
                                    await _api.grantSubscription(user['id']);
                                    await _load();
                                  },
                                ),
                              ),
                          ],
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

  Widget _detail(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text('${value ?? '-'}')),
          ],
        ),
      );
}
