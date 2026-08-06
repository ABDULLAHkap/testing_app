import 'dart:async';
import 'package:flutter/material.dart';

class ExamCountdownCard extends StatefulWidget {
  final String username;
  final DateTime? examDate;
  final VoidCallback onSetDate;
  final String examName;

  const ExamCountdownCard({
    super.key,
    required this.username,
    required this.examDate,
    required this.onSetDate,
    this.examName = 'Exam',
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
    const cyan = Color(0xFF20D5C5);
    const surface = Color(0xFF101F32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3B51)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          if (widget.examDate == null) ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: const BoxDecoration(
                color: Color(0x1820D5C5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_bottom_rounded, color: cyan, size: 34),
            ),
            const SizedBox(height: 10),
            Text(
              "Set your ${widget.examName} date to start your countdown",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: cyan),
              onPressed: widget.onSetDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text("Set exam date"),
            ),
          ] else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Color(0x1820D5C5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_bottom_rounded, color: cyan, size: 34),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Exam starts in",
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  _timeBox(_remaining.inDays, "Days"),
                  _separator(),
                  _timeBox(_remaining.inHours % 24, "Hours"),
                  _separator(),
                  _timeBox(_remaining.inMinutes % 60, "Mins"),
                  _separator(),
                  _timeBox(_remaining.inSeconds % 60, "Secs"),
                ],
              ),
            ),
            const SizedBox(height: 5),
            TextButton.icon(
              onPressed: widget.onSetDate,
              icon: const Icon(Icons.edit_calendar_outlined, size: 17),
              label: Text("Change date • ${_formatDate(widget.examDate!)}"),
              style: TextButton.styleFrom(foregroundColor: cyan),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeBox(int value, String label) {
    return Container(
        width: 68,
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0C192A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3B51)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value.toString().padLeft(2, '0'),
                style: const TextStyle(
                    color: Color(0xFF20D5C5), fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
    );
  }

  Widget _separator() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 5),
    child: Text(':', style: TextStyle(color: Colors.white30, fontSize: 20)),
  );

  String _formatDate(DateTime d) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }
}
