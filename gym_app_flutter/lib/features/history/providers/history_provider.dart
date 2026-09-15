import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';

final historyProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.workoutSessions)
        ..where((s) => s.isCompleted.equals(true))
        ..orderBy([(s) => drift.OrderingTerm(expression: s.startTime, mode: drift.OrderingMode.desc)]))
      .watch();
});

final workoutDetailProvider = FutureProvider.family<WorkoutDetail?, int>((ref, sessionId) async {
  final database = ref.watch(databaseProvider);

  try {
    final session = await (database.select(database.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingle();

    final setLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(sessionId))
          ..where((s) => s.isCompleted.equals(true)))
        .get();

    // Group by exercise
    final Map<int?, List<SetLog>> exerciseGroups = {};
    for (final log in setLogs) {
      exerciseGroups.putIfAbsent(log.exerciseId, () => []).add(log);
    }

    // Get exercise names
    final exercises = <int, Exercise>{};
    for (final exerciseId in exerciseGroups.keys) {
      if (exerciseId != null) {
        final exercise = await (database.select(database.exercises)
              ..where((e) => e.id.equals(exerciseId)))
            .getSingle();
        exercises[exerciseId] = exercise;
      }
    }

    return WorkoutDetail(
      session: session,
      setLogs: setLogs,
      exerciseGroups: exerciseGroups,
      exercises: exercises,
    );
  } catch (e) {
    return null;
  }
});

class WorkoutDetail {
  final WorkoutSession session;
  final List<SetLog> setLogs;
  final Map<int?, List<SetLog>> exerciseGroups;
  final Map<int, Exercise> exercises;

  WorkoutDetail({
    required this.session,
    required this.setLogs,
    required this.exerciseGroups,
    required this.exercises,
  });

  double get totalVolume {
    return setLogs.fold(0.0, (sum, log) => sum + (log.actualWeight * log.actualReps));
  }

  int get totalSets => setLogs.length;
}
