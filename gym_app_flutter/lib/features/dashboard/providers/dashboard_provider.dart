import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';

class DashboardStats {
  final int workoutsThisWeek;
  final int totalSetsThisWeek;
  final double totalVolumeThisWeek;
  final List<WorkoutSession> recentWorkouts;

  const DashboardStats({
    required this.workoutsThisWeek,
    required this.totalSetsThisWeek,
    required this.totalVolumeThisWeek,
    required this.recentWorkouts,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final database = ref.watch(databaseProvider);

  // Get start of this week (Monday)
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

  // Get workouts this week
  final workoutsThisWeek = await (database.select(database.workoutSessions)
        ..where((s) => s.startTime.isBiggerOrEqualValue(weekStartMidnight))
        ..where((s) => s.isCompleted.equals(true)))
      .get();

  // Get set logs this week
  int totalSets = 0;
  double totalVolume = 0.0;

  for (final workout in workoutsThisWeek) {
    final setLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(workout.id))
          ..where((s) => s.isCompleted.equals(true)))
        .get();

    totalSets += setLogs.length;
    totalVolume += setLogs.fold(0.0, (sum, log) => sum + (log.actualWeight * log.actualReps));
  }

  // Get recent 5 workouts
  final recentWorkouts = await (database.select(database.workoutSessions)
        ..where((s) => s.isCompleted.equals(true))
        ..orderBy([(s) => drift.OrderingTerm(expression: s.startTime, mode: drift.OrderingMode.desc)])
        ..limit(5))
      .get();

  return DashboardStats(
    workoutsThisWeek: workoutsThisWeek.length,
    totalSetsThisWeek: totalSets,
    totalVolumeThisWeek: totalVolume,
    recentWorkouts: recentWorkouts,
  );
});

// Provider for all routines
final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await (database.select(database.routines)
        ..where((r) => r.isTemplate.equals(false))
        ..orderBy([(r) => drift.OrderingTerm(expression: r.createdAt, mode: drift.OrderingMode.desc)]))
      .get();
});
