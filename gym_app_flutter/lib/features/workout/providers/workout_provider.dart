import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';
import '../../../core/models/enums.dart';
import '../models/workout_state.dart';
import '../logic/progression_engine.dart';

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final AppDatabase database;
  Timer? _restTimer;

  WorkoutNotifier(this.database) : super(const WorkoutState());

  // Start a new workout from a routine
  Future<void> startWorkout(int routineId) async {
    // Get routine exercises
    final routineExercises = await (database.select(database.routineExercises)
          ..where((re) => re.routineId.equals(routineId))
          ..orderBy([(re) => drift.OrderingTerm(expression: re.order)]))
        .get();

    // Create workout session
    final sessionId = await database.into(database.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            routineId: drift.Value(routineId),
            startTime: drift.Value(DateTime.now()),
            notes: const drift.Value(''),
            isCompleted: const drift.Value(false),
          ),
        );

    // Create set logs for all exercises
    final setLogs = <SetLog>[];
    for (final routineExercise in routineExercises) {
      for (int setNumber = 1; setNumber <= routineExercise.targetSets; setNumber++) {
        final setLogId = await database.into(database.setLogs).insert(
              SetLogsCompanion.insert(
                sessionId: sessionId,
                exerciseId: drift.Value(routineExercise.exerciseId),
                setNumber: setNumber,
                targetWeight: 0.0, // User will set
                actualWeight: 0.0,
                targetReps: routineExercise.targetRepMin,
                actualReps: 0,
                unit: WeightUnit.lb.name,
                isWarmup: const drift.Value(false),
                timestamp: drift.Value(DateTime.now()),
                isCompleted: const drift.Value(false),
              ),
            );

        final setLog = await (database.select(database.setLogs)
              ..where((s) => s.id.equals(setLogId)))
            .getSingle();
        setLogs.add(setLog);
      }
    }

    // Get the created session
    final session = await (database.select(database.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingle();

    state = state.copyWith(
      session: session,
      routineExercises: routineExercises,
      setLogs: setLogs,
      currentExerciseIndex: 0,
      isWorkoutActive: true,
    );
  }

  // Finish the workout
  Future<void> finishWorkout() async {
    if (state.session == null) return;

    // Mark workout as completed
    await (database.update(database.workoutSessions)
          ..where((s) => s.id.equals(state.session!.id)))
        .write(
      WorkoutSessionsCompanion(
        endTime: drift.Value(DateTime.now()),
        isCompleted: const drift.Value(true),
      ),
    );

    // Apply progression rules
    final progressionResults = <ProgressionResult>[];
    for (final routineExercise in state.routineExercises) {
      // Get exercise
      final exerciseId = routineExercise.exerciseId;
      if (exerciseId == null) continue;

      final exercise = await (database.select(database.exercises)
            ..where((e) => e.id.equals(exerciseId)))
          .getSingleOrNull();

      if (exercise == null) continue;

      // Get set logs for this exercise
      final exerciseSetLogs = state.setLogs
          .where((log) => log.exerciseId == exerciseId)
          .toList();

      // Get progression rule
      final progressionRuleId = routineExercise.progressionRuleId;
      if (progressionRuleId == null) continue;

      final progressionRule = await (database.select(database.progressionRules)
            ..where((pr) => pr.id.equals(progressionRuleId)))
          .getSingleOrNull();

      if (progressionRule == null) continue;

      // Evaluate progression
      final result = ProgressionEngine.evaluate(
        exercise: exercise,
        setLogs: exerciseSetLogs,
        progressionRule: progressionRule,
        routineExercise: routineExercise,
      );

      progressionResults.add(result);

      // Update routine exercise weight if changed
      if (result.newWeight != result.previousWeight) {
        await (database.update(database.routineExercises)
              ..where((re) => re.id.equals(routineExercise.id)))
            .write(
          RoutineExercisesCompanion(
            defaultWeight: drift.Value(result.newWeight),
          ),
        );
      }

      // Update progression rule consecutive failures
      await (database.update(database.progressionRules)
            ..where((pr) => pr.id.equals(progressionRule.id)))
          .write(
        ProgressionRulesCompanion(
          consecutiveFailures: drift.Value(result.newConsecutiveFailures),
        ),
      );
    }

    stopRestTimer();
    state = state.copyWith(
      isWorkoutActive: false,
      progressionResults: progressionResults,
    );
  }

  // Cancel the workout
  Future<void> cancelWorkout() async {
    if (state.session == null) return;

    // Delete session (cascade will delete set logs)
    await (database.delete(database.workoutSessions)
          ..where((s) => s.id.equals(state.session!.id)))
        .go();

    stopRestTimer();
    state = const WorkoutState();
  }

  // Complete a set
  Future<void> completeSet(SetLog setLog, int actualReps, double actualWeight) async {
    await (database.update(database.setLogs)
          ..where((s) => s.id.equals(setLog.id)))
        .write(
      SetLogsCompanion(
        actualReps: drift.Value(actualReps),
        actualWeight: drift.Value(actualWeight),
        isCompleted: const drift.Value(true),
        timestamp: drift.Value(DateTime.now()),
      ),
    );

    // Reload set logs
    final updatedSetLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(state.session!.id)))
        .get();

    state = state.copyWith(setLogs: updatedSetLogs);

    // Auto-start rest timer
    final currentExercise = state.currentRoutineExercise;
    if (currentExercise != null && currentExercise.restSeconds > 0) {
      startRestTimer(currentExercise.restSeconds);
    }
  }

  // Uncomplete a set
  Future<void> uncompleteSet(SetLog setLog) async {
    await (database.update(database.setLogs)
          ..where((s) => s.id.equals(setLog.id)))
        .write(
      const SetLogsCompanion(
        isCompleted: drift.Value(false),
        actualReps: drift.Value(0),
      ),
    );

    // Reload set logs
    final updatedSetLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(state.session!.id)))
        .get();

    state = state.copyWith(setLogs: updatedSetLogs);
  }

  // Navigation
  void nextExercise() {
    if (state.currentExerciseIndex < state.totalExercises - 1) {
      stopRestTimer();
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      stopRestTimer();
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
    }
  }

  void goToExercise(int index) {
    if (index >= 0 && index < state.totalExercises) {
      stopRestTimer();
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  // Rest Timer
  void startRestTimer(int seconds) {
    stopRestTimer();
    state = state.copyWith(
      restTimeRemaining: seconds,
      isRestTimerRunning: true,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimeRemaining > 0) {
        state = state.copyWith(restTimeRemaining: state.restTimeRemaining - 1);
      } else {
        stopRestTimer();
      }
    });
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    state = state.copyWith(
      isRestTimerRunning: false,
      restTimeRemaining: 0,
    );
  }

  void extendRestTimer([int seconds = 30]) {
    state = state.copyWith(restTimeRemaining: state.restTimeRemaining + seconds);
  }

  // Weight Adjustments
  Future<void> incrementWeight(SetLog setLog, [double amount = 5.0]) async {
    final newWeight = setLog.targetWeight + amount;
    await (database.update(database.setLogs)
          ..where((s) => s.id.equals(setLog.id)))
        .write(
      SetLogsCompanion(
        targetWeight: drift.Value(newWeight),
        actualWeight: drift.Value(newWeight),
      ),
    );

    // Reload set logs
    final updatedSetLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(state.session!.id)))
        .get();

    state = state.copyWith(setLogs: updatedSetLogs);
  }

  Future<void> decrementWeight(SetLog setLog, [double amount = 5.0]) async {
    final newWeight = (setLog.targetWeight - amount).clamp(0.0, double.infinity);
    await (database.update(database.setLogs)
          ..where((s) => s.id.equals(setLog.id)))
        .write(
      SetLogsCompanion(
        targetWeight: drift.Value(newWeight),
        actualWeight: drift.Value(newWeight),
      ),
    );

    // Reload set logs
    final updatedSetLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(state.session!.id)))
        .get();

    state = state.copyWith(setLogs: updatedSetLogs);
  }

  Future<void> setWeightForAllSets(double weight) async {
    final currentExercise = state.currentRoutineExercise;
    if (currentExercise == null) return;

    for (final setLog in state.currentSetLogs) {
      if (!setLog.isWarmup) {
        await (database.update(database.setLogs)
              ..where((s) => s.id.equals(setLog.id)))
            .write(
          SetLogsCompanion(
            targetWeight: drift.Value(weight),
            actualWeight: setLog.isCompleted ? drift.Value(setLog.actualWeight) : drift.Value(weight),
          ),
        );
      }
    }

    // Reload set logs
    final updatedSetLogs = await (database.select(database.setLogs)
          ..where((s) => s.sessionId.equals(state.session!.id)))
        .get();

    state = state.copyWith(setLogs: updatedSetLogs);
  }

  @override
  void dispose() {
    stopRestTimer();
    super.dispose();
  }
}

// Provider
final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final database = ref.watch(databaseProvider);
  return WorkoutNotifier(database);
});
