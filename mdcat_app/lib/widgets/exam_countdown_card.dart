import 'dart:async';
import 'package:flutter/material.dart';

class ExamCountdownCard extends StatefulWidget {
  final String username;
  final DateTime? examDate;
  final VoidCallback onSetDate;

  const ExamCountdownCard({
    super.key,
    required this.username,
    required this.examDate,
    required this.onSetDate,
  });

  @override
  State<ExamCountdownCard> createState() => _ExamCountdownCardState();
}

class _ExamCountdownCardState extends State<ExamCountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (widget.examDate == null) return;
    final now = DateTime.now();
    final diff = widget.examDate!.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D9E75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: teal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "Hello, ${widget.username}!",
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          if (widget.examDate == null) ...[
            const Text(
              "Set your MDCAT exam date to start your countdown",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              onPressed: widget.onSetDate,
              child: const Text("Set Exam Date"),
            ),
          ] else ...[
            const Text(
              "MDCAT starts in",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              _formatDate(widget.examDate!),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeBox(_remaining.inDays, "days"),
                const SizedBox(width: 8),
                _timeBox(_remaining.inHours % 24, "hrs"),
                const SizedBox(width: 8),
                _timeBox(_remaining.inMinutes % 60, "min"),
                const SizedBox(width: 8),
                _timeBox(_remaining.inSeconds % 60, "sec"),
              ],
            ),
            TextButton(
              onPressed: widget.onSetDate,
              child: const Text("Change date",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeBox(int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value.toString().padLeft(2, '0'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }
}
