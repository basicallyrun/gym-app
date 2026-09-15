import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';

// Provider for all routines
final routineListProvider = StreamProvider<List<Routine>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.routines)
        ..where((r) => r.isTemplate.equals(false))
        ..orderBy([(r) => drift.OrderingTerm(expression: r.createdAt, mode: drift.OrderingMode.desc)]))
      .watch();
});

// Provider for a specific routine with exercises
final routineDetailProvider = FutureProvider.family<RoutineWithExercises?, int>((ref, routineId) async {
  final database = ref.watch(databaseProvider);

  try {
    final routine = await (database.select(database.routines)
          ..where((r) => r.id.equals(routineId)))
        .getSingle();

    final routineExercises = await (database.select(database.routineExercises)
          ..where((re) => re.routineId.equals(routineId))
          ..orderBy([(re) => drift.OrderingTerm(expression: re.order)]))
        .get();

    final exercises = <Exercise>[];
    for (final re in routineExercises) {
      if (re.exerciseId != null) {
        final exercise = await (database.select(database.exercises)
              ..where((e) => e.id.equals(re.exerciseId!)))
            .getSingle();
        exercises.add(exercise);
      }
    }

    return RoutineWithExercises(
      routine: routine,
      routineExercises: routineExercises,
      exercises: exercises,
    );
  } catch (e) {
    return null;
  }
});

// Provider for all exercises (for picker)
final exerciseListProvider = StreamProvider<List<Exercise>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.exercises)..orderBy([(e) => drift.OrderingTerm(expression: e.name)])).watch();
});

class RoutineWithExercises {
  final Routine routine;
  final List<RoutineExercise> routineExercises;
  final List<Exercise> exercises;

  RoutineWithExercises({
    required this.routine,
    required this.routineExercises,
    required this.exercises,
  });
}

// Routine mutations
class RoutineService {
  final AppDatabase database;

  RoutineService(this.database);

  Future<int> createRoutine(String name) async {
    return await database.into(database.routines).insert(
          RoutinesCompanion.insert(
            name: name,
            isTemplate: const drift.Value(false),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteRoutine(int routineId) async {
    await (database.delete(database.routines)..where((r) => r.id.equals(routineId))).go();
  }

  Future<void> updateRoutineName(int routineId, String name) async {
    await (database.update(database.routines)..where((r) => r.id.equals(routineId)))
        .write(RoutinesCompanion(name: drift.Value(name)));
  }

  Future<int> addExerciseToRoutine({
    required int routineId,
    required int exerciseId,
    required int order,
    int targetSets = 3,
    int targetRepMin = 5,
    int targetRepMax = 5,
    int restSeconds = 90,
  }) async {
    return await database.into(database.routineExercises).insert(
          RoutineExercisesCompanion.insert(
            routineId: routineId,
            exerciseId: drift.Value(exerciseId),
            order: drift.Value(order),
            targetSets: drift.Value(targetSets),
            targetRepMin: drift.Value(targetRepMin),
            targetRepMax: drift.Value(targetRepMax),
            restSeconds: drift.Value(restSeconds),
          ),
        );
  }

  Future<void> removeExerciseFromRoutine(int routineExerciseId) async {
    await (database.delete(database.routineExercises)..where((re) => re.id.equals(routineExerciseId))).go();
  }

  Future<void> updateRoutineExercise({
    required int routineExerciseId,
    int? targetSets,
    int? targetRepMin,
    int? targetRepMax,
    int? restSeconds,
  }) async {
    await (database.update(database.routineExercises)..where((re) => re.id.equals(routineExerciseId))).write(
      RoutineExercisesCompanion(
        targetSets: targetSets != null ? drift.Value(targetSets) : const drift.Value.absent(),
        targetRepMin: targetRepMin != null ? drift.Value(targetRepMin) : const drift.Value.absent(),
        targetRepMax: targetRepMax != null ? drift.Value(targetRepMax) : const drift.Value.absent(),
        restSeconds: restSeconds != null ? drift.Value(restSeconds) : const drift.Value.absent(),
      ),
    );
  }

  Future<void> reorderRoutineExercises(int routineId, List<int> routineExerciseIds) async {
    for (int i = 0; i < routineExerciseIds.length; i++) {
      await (database.update(database.routineExercises)..where((re) => re.id.equals(routineExerciseIds[i])))
          .write(RoutineExercisesCompanion(order: drift.Value(i)));
    }
  }
}

final routineServiceProvider = Provider<RoutineService>((ref) {
  final database = ref.watch(databaseProvider);
  return RoutineService(database);
});
