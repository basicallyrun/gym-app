import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/providers.dart';
import '../../settings/providers/settings_provider.dart';

class ExerciseProgressScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const ExerciseProgressScreen({
    required this.exerciseId,
    required this.exerciseName,
    super.key,
  });

  @override
  ConsumerState<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends ConsumerState<ExerciseProgressScreen> {
  List<FlSpot> _dataPoints = [];
  List<DateTime> _timestamps = [];
  double _minY = 0;
  double _maxY = 100;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final database = ref.read(databaseProvider);

    // Get all set logs for this exercise, grouped by session
    final query = database.select(database.setLogs).join([
      drift.innerJoin(
        database.workoutSessions,
        database.workoutSessions.id.equalsExp(database.setLogs.sessionId),
      ),
    ])
      ..where(
        database.setLogs.exerciseId.equals(widget.exerciseId) &
            database.setLogs.isCompleted.equals(true) &
            database.setLogs.isWarmup.equals(false),
      )
      ..orderBy([drift.OrderingTerm.asc(database.workoutSessions.startTime)]);

    final results = await query.get();

    // Group by session and calculate max weight per session
    final Map<int, SessionData> sessionData = {};
    for (final row in results) {
      final setLog = row.readTable(database.setLogs);
      final session = row.readTable(database.workoutSessions);

      if (!sessionData.containsKey(session.id)) {
        sessionData[session.id] = SessionData(
          timestamp: session.startTime,
          maxWeight: setLog.actualWeight,
        );
      } else {
        final current = sessionData[session.id]!;
        if (setLog.actualWeight > current.maxWeight) {
          sessionData[session.id] = SessionData(
            timestamp: current.timestamp,
            maxWeight: setLog.actualWeight,
          );
        }
      }
    }

    // Convert to chart data points
    final sessions = sessionData.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sessions.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final dataPoints = <FlSpot>[];
    final timestamps = <DateTime>[];

    for (int i = 0; i < sessions.length; i++) {
      dataPoints.add(FlSpot(i.toDouble(), sessions[i].maxWeight));
      timestamps.add(sessions[i].timestamp);
    }

    // Calculate Y axis range
    final weights = sessions.map((s) => s.maxWeight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.1;

    setState(() {
      _dataPoints = dataPoints;
      _timestamps = timestamps;
      _minY = (minWeight - padding).clamp(0, double.infinity);
      _maxY = maxWeight + padding;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final weightUnit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataPoints.isEmpty
              ? const Center(
                  child: Text('No workout data yet for this exercise'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showing max weight per workout session',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            minY: _minY,
                            maxY: _maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (_maxY - _minY) / 5,
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= _timestamps.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = _timestamps[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('M/d').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _dataPoints,
                                isCurved: true,
                                color: Theme.of(context).colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final index = spot.x.toInt();
                                    final date = _timestamps[index];
                                    return LineTooltipItem(
                                      '${spot.y.toStringAsFixed(1)} $weightUnit\n${DateFormat('MMM d, y').format(date)}',
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStats(weightUnit),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStats(String weightUnit) {
    if (_dataPoints.isEmpty) return const SizedBox.shrink();

    final startWeight = _dataPoints.first.y;
    final currentWeight = _dataPoints.last.y;
    final totalGain = currentWeight - startWeight;
    final percentGain = (totalGain / startWeight) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Starting',
                  value: '${startWeight.toStringAsFixed(1)} $weightUnit',
                ),
                _StatItem(
                  label: 'Current',
                  value: '${currentWeight.toStringAsFixed(1)} $weightUnit',
                ),
                _StatItem(
                  label: 'Total Gain',
                  value: '${totalGain >= 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} $weightUnit',
                  color: totalGain >= 0 ? Colors.green : Colors.red,
                ),
                _StatItem(
                  label: 'Change',
                  value: '${percentGain >= 0 ? '+' : ''}${percentGain.toStringAsFixed(1)}%',
                  color: percentGain >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SessionData {
  final DateTime timestamp;
  final double maxWeight;

  SessionData({
    required this.timestamp,
    required this.maxWeight,
  });
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
