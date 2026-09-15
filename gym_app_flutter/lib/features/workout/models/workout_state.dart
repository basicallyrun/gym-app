import '../../../core/database/database.dart';
import '../logic/progression_engine.dart';

class WorkoutState {
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final bool isRestTimerRunning;
  final int restTimeRemaining;
  final bool isWorkoutActive;
  final List<RoutineExercise> routineExercises;
  final List<SetLog> setLogs;
  final List<ProgressionResult> progressionResults;

  const WorkoutState({
    this.session,
    this.currentExerciseIndex = 0,
    this.isRestTimerRunning = false,
    this.restTimeRemaining = 0,
    this.isWorkoutActive = false,
    this.routineExercises = const [],
    this.setLogs = const [],
    this.progressionResults = const [],
  });

  WorkoutState copyWith({
    WorkoutSession? session,
    int? currentExerciseIndex,
    bool? isRestTimerRunning,
    int? restTimeRemaining,
    bool? isWorkoutActive,
    List<RoutineExercise>? routineExercises,
    List<SetLog>? setLogs,
    List<ProgressionResult>? progressionResults,
  }) {
    return WorkoutState(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isRestTimerRunning: isRestTimerRunning ?? this.isRestTimerRunning,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isWorkoutActive: isWorkoutActive ?? this.isWorkoutActive,
      routineExercises: routineExercises ?? this.routineExercises,
      setLogs: setLogs ?? this.setLogs,
      progressionResults: progressionResults ?? this.progressionResults,
    );
  }

  RoutineExercise? get currentRoutineExercise {
    if (currentExerciseIndex >= 0 && currentExerciseIndex < routineExercises.length) {
      return routineExercises[currentExerciseIndex];
    }
    return null;
  }

  List<SetLog> get currentSetLogs {
    final currentExercise = currentRoutineExercise;
    if (currentExercise == null) return [];

    return setLogs
        .where((log) => log.exerciseId == currentExercise.exerciseId)
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  int get totalExercises => routineExercises.length;

  int get completedSetsCount => setLogs.where((log) => log.isCompleted).length;

  int get totalSetsCount => routineExercises.fold(0, (sum, re) => sum + re.targetSets);
}
