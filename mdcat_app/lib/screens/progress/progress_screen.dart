import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ApiClient _api = ApiClient();
  List<ProgressPoint> _points = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final points = await _api.getProgress();
      // Most recent first for the list view.
      points.sort((a, b) {
        final aDate = a.finishedAt ?? DateTime(2000);
        final bDate = b.finishedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      setState(() => _points = points);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case "A+":
      case "A":
        return Colors.green;
      case "B":
        return Colors.lightGreen;
      case "C":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Progress")),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _points.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(child: Text("Couldn't load progress: $_error")),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: _load, child: const Text("Retry")),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.query_stats, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "No quizzes yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Text(
              "Take your first quiz from Practice by Topic or Full Mock Test "
              "on the dashboard — your results will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    // Summary header: overall average across all attempts shown.
    final avg = _points.isEmpty
        ? 0.0
        : _points.map((p) => p.percentage).reduce((a, b) => a + b) /
            _points.length;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _points.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryStat("${_points.length}", "Total Attempts"),
                    _summaryStat("${avg.toStringAsFixed(1)}%", "Overall Avg"),
                  ],
                ),
              ),
            ),
          );
        }

        final point = _points[index - 1];
        final dateStr = point.finishedAt != null
            ? DateFormat('MMM d, y • h:mm a').format(point.finishedAt!.toLocal())
            : "In progress";

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _gradeColor(point.grade).withOpacity(0.15),
              child: Text(
                point.grade,
                style: TextStyle(
                  color: _gradeColor(point.grade),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text("${point.subject} • ${point.difficulty}"),
            subtitle: Text(dateStr),
            trailing: Text(
              "${point.percentage.toStringAsFixed(0)}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
