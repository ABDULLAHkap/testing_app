import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_provider.dart';

class ExamCategoryScreen extends StatefulWidget {
  const ExamCategoryScreen({super.key});

  @override
  State<ExamCategoryScreen> createState() => _ExamCategoryScreenState();
}

class _ExamCategoryScreenState extends State<ExamCategoryScreen> {
  static const _exams = <String>[
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

  bool _saving = false;

  Future<void> _changeExam(String exam) async {
    final auth = context.read<AuthProvider>();
    final current = auth.currentUser?.targetExam;
    if (current == exam || _saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Switch to $exam?'),
        content: Text(
          'Your account keeps only 3 free tests in total across all exam categories. '
          'After those are used, each exam category needs its own subscription. '
          'Switching category does not transfer a paid subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Switch category'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final api = ApiClient();
      final baseUrl = await api.getBaseUrl();
      final token = await api.getToken();
      if (token == null) throw Exception('Please sign in again.');
      final response = await http.put(
        Uri.parse('$baseUrl/account/exam-category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'target_exam': exam}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'Could not change exam category';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['detail'] != null) {
            message = body['detail'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exam category changed to $exam')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AuthProvider>().currentUser?.targetExam ?? 'MDCAT';
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Category')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose which exam you are preparing for. Tests, mock tests, adaptive practice, progress and past papers will follow the selected category.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Free trial: 3 completed tests per account in total. Paid access is purchased separately for each exam category.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ..._exams.map(
            (exam) => Card(
              child: RadioListTile<String>(
                value: exam,
                groupValue: current,
                onChanged: _saving ? null : (value) {
                  if (value != null) _changeExam(value);
                },
                title: Text(exam),
                secondary: exam == current
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.school_outlined),
              ),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
