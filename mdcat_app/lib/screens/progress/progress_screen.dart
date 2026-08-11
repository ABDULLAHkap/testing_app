import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home_navigation_action.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ApiClient _api = ApiClient();
  List<ProgressPoint> _points = [];
  AdvancedAnalytics? _analytics;
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
      final results = await Future.wait([
        _api.getProgress(),
        _api.getAdvancedAnalytics(),
      ]);
      final points = results[0] as List<ProgressPoint>;
      points.sort(
        (a, b) => (b.finishedAt ?? DateTime(2000)).compareTo(
          a.finishedAt ?? DateTime(2000),
        ),
      );
      if (!mounted) return;
      setState(() {
        _points = points;
        _analytics = results[1] as AdvancedAnalytics;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        actions: const [HomeNavigationAction()],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorView()
            : _points.isEmpty
            ? _emptyView()
            : _content(),
      ),
    );
  }

  Widget _errorView() => ListView(
    children: [
      const SizedBox(height: 100),
      Center(child: Text("Couldn't load analytics: $_error")),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
      ),
    ],
  );

  Widget _emptyView() => ListView(
    padding: const EdgeInsets.all(32),
    children: [
      const SizedBox(height: 70),
      Icon(Icons.insights_outlined, size: 68, color: context.inactiveColor),
      const SizedBox(height: 16),
      Text(
        'Your analytics will appear after your first test.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.primaryTextColor, fontSize: 17),
      ),
    ],
  );

  Widget _content() {
    final a = _analytics!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _summary('${a.testsCompleted}', 'Tests')),
            const SizedBox(width: 8),
            Expanded(
              child: _summary(
                '${a.averageScore.toStringAsFixed(1)}%',
                'Average',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summary('${a.bestScore.toStringAsFixed(1)}%', 'Best'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _weeklyChart(a.weeklyImprovement),
        const SizedBox(height: 14),
        if (a.latestScore != null) _comparison(a),
        const SizedBox(height: 14),
        _twoColumnTopics(a.strongestTopics, a.weakestTopics),
        const SizedBox(height: 14),
        _metricSection('Subject-wise scores', a.subjectScores),
        const SizedBox(height: 14),
        _metricSection('Topic-wise scores and time', a.topicScores),
        const SizedBox(height: 18),
        Text('Recent attempts', style: _headingStyle),
        const SizedBox(height: 8),
        ..._points.take(12).map(_attemptTile),
      ],
    );
  }

  TextStyle get _headingStyle => TextStyle(
    color: context.primaryTextColor,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  Widget _summary(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: context.secondaryTextColor, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _weeklyChart(List<WeeklyPerformance> weeks) => Container(
    height: 245,
    padding: const EdgeInsets.fromLTRB(14, 16, 18, 12),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly improvement', style: _headingStyle),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.subtleBorderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 25,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= weeks.length || i.isOdd)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('d MMM').format(weeks[i].weekStart),
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < weeks.length; i++)
                      FlSpot(i.toDouble(), weeks[i].averageScore),
                  ],
                  isCurved: true,
                  color: const Color(0xFF20D5C5),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF20D5C5).withOpacity(.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _comparison(AdvancedAnalytics a) {
    final change = a.change;
    final up = (change ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(
            up ? Icons.trending_up : Icons.trending_down,
            color: up ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              a.previousScore == null
                  ? 'Latest result: ${a.latestScore!.toStringAsFixed(1)}%'
                  : 'Latest ${a.latestScore!.toStringAsFixed(1)}% vs previous ${a.previousScore!.toStringAsFixed(1)}%',
              style: TextStyle(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (change != null)
            Text(
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                color: up ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _twoColumnTopics(
    List<PerformanceMetric> strong,
    List<PerformanceMetric> weak,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _topicCard('Strongest', strong, Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _topicCard('Needs practice', weak, Colors.orange)),
    ],
  );

  Widget _topicCard(
    String title,
    List<PerformanceMetric> values,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            'More results needed',
            style: TextStyle(color: context.secondaryTextColor, fontSize: 11),
          )
        else
          ...values
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${item.name}  ${item.accuracy.toStringAsFixed(0)}%',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
      ],
    ),
  );

  Widget _metricSection(
    String title,
    List<PerformanceMetric> values,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _headingStyle),
        const SizedBox(height: 12),
        ...values.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subject == null
                            ? item.name
                            : '${item.subject} • ${item.name}',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${item.accuracy.toStringAsFixed(0)}% • ${item.averageTimeSeconds.toStringAsFixed(0)}s/q',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (item.accuracy / 100).clamp(0, 1).toDouble(),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  color: item.accuracy >= 75
                      ? Colors.green
                      : item.accuracy >= 50
                      ? Colors.orange
                      : Colors.red,
                  backgroundColor: context.subtleBorderColor,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _attemptTile(ProgressPoint point) => Card(
    color: context.panelColor,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(
        '${point.subject} • ${point.difficulty}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        point.finishedAt == null
            ? 'In progress'
            : DateFormat(
                'MMM d, y • h:mm a',
              ).format(point.finishedAt!.toLocal()),
      ),
      trailing: Text(
        '${point.percentage.toStringAsFixed(0)}%',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: context.panelColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: context.subtleBorderColor),
  );
}
