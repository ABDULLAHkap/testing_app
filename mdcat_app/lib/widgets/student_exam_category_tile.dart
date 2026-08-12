import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../services/exam_category_service.dart';
import '../utils/exam_content.dart';

class StudentExamCategoryTile extends StatefulWidget {
  const StudentExamCategoryTile({super.key});

  @override
  State<StudentExamCategoryTile> createState() => _StudentExamCategoryTileState();
}

class _StudentExamCategoryTileState extends State<StudentExamCategoryTile> {
  final ExamCategoryService _categoryService = ExamCategoryService();
  final ApiClient _api = ApiClient();
  bool _saving = false;
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _api.getSubscriptionStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  Future<void> _changeCategory() async {
    final auth = context.read<AuthProvider>();
    final current = auth.currentUser?.targetExam ?? 'MDCAT';
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Change exam category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Your 3 free tests are shared across the whole account. Paid access is purchased separately for each exam category.',
              ),
            ),
            ...examSubjects.keys.map(
              (exam) => ListTile(
                title: Text(exam),
                trailing: exam == current
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () => Navigator.pop(sheetContext, exam),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || selected == current || !mounted) return;

    setState(() => _saving = true);
    try {
      await _categoryService.updateCategory(selected);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      await _loadStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exam category changed to $selected')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change exam category: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null || user.isAdmin) return const SizedBox.shrink();

    final category = user.targetExam;
    final expiryText = _status?['subscription_expires_at'] == null
        ? 'No active paid subscription for $category'
        : 'Paid access active for $category';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.swap_horiz_rounded),
      title: Text('Exam Category: $category'),
      subtitle: Text(
        '$expiryText\n${user.freeTestsRemaining} of 3 free tests remaining on this account',
      ),
      isThreeLine: true,
      trailing: _saving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _saving ? null : _changeCategory,
    );
  }
}
