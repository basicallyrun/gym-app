import '../../../core/database/database.dart';
import '../../../core/models/enums.dart';

class ProgressionResult {
  final String exerciseName;
  final double previousWeight;
  final double newWeight;
  final bool passed;
  final bool deloaded;
  final String message;
  final int newConsecutiveFailures;

  const ProgressionResult({
    required this.exerciseName,
    required this.previousWeight,
    required this.newWeight,
    required this.passed,
    required this.deloaded,
    required this.message,
    required this.newConsecutiveFailures,
  });
}

class ProgressionEngine {
  /// Evaluate workout results for a single exercise and apply progression rules.
  /// Returns the result describing what changed.
  static ProgressionResult evaluate({
    required Exercise exercise,
    required List<SetLog> setLogs,
    required ProgressionRule progressionRule,
    required RoutineExercise routineExercise,
  }) {
    final workingSets = setLogs.where((log) => !log.isWarmup && log.isCompleted).toList();

    if (workingSets.isEmpty) {
      return ProgressionResult(
        exerciseName: exercise.name,
        previousWeight: setLogs.isNotEmpty ? setLogs.first.targetWeight : 0,
        newWeight: setLogs.isNotEmpty ? setLogs.first.targetWeight : 0,
        passed: false,
        deloaded: false,
        message: 'No working sets completed',
        newConsecutiveFailures: progressionRule.consecutiveFailures,
      );
    }

    final currentWeight = workingSets.first.targetWeight;

    // Parse trigger type from string
    final triggerType = ProgressionTrigger.values.firstWhere(
      (e) => e.name == progressionRule.triggerType,
      orElse: () => ProgressionTrigger.allSetsCompleted,
    );

    final bool passed;
    switch (triggerType) {
      case ProgressionTrigger.allSetsCompleted:
        // All prescribed sets must be completed at or above target reps
        final targetSets = routineExercise.targetSets;
        final targetRepMin = routineExercise.targetRepMin;
        final completedAtTarget = workingSets.where((log) => log.actualReps >= targetRepMin).toList();
        passed = completedAtTarget.length >= targetSets;
        break;

      case ProgressionTrigger.topSetHit:
        // Only the heaviest set needs to hit target reps
        final topSet = workingSets.reduce((a, b) => a.actualWeight > b.actualWeight ? a : b);
        passed = topSet.actualReps >= routineExercise.targetRepMin;
        break;
    }

    if (passed) {
      // Success: increase weight, reset failure count
      final newWeight = currentWeight + progressionRule.incrementAmount;
      return ProgressionResult(
        exerciseName: exercise.name,
        previousWeight: currentWeight,
        newWeight: newWeight,
        passed: true,
        deloaded: false,
        message: 'Increase weight to ${_formatted(newWeight)} ${progressionRule.unit}',
        newConsecutiveFailures: 0,
      );
    } else {
      // Failure: check if deload is needed
      final newFailureCount = progressionRule.consecutiveFailures + 1;

      if (newFailureCount >= progressionRule.deloadAfterFailures) {
        // Deload triggered
        final deloadAmount = currentWeight * progressionRule.deloadPercentage;
        final newWeight = _roundToNearest(
          currentWeight - deloadAmount,
          increment: progressionRule.incrementAmount,
        );
        return ProgressionResult(
          exerciseName: exercise.name,
          previousWeight: currentWeight,
          newWeight: newWeight,
          passed: false,
          deloaded: true,
          message: 'Deload to ${_formatted(newWeight)} ${progressionRule.unit} after ${progressionRule.deloadAfterFailures} consecutive failures',
          newConsecutiveFailures: 0,
        );
      } else {
        // Keep same weight
        return ProgressionResult(
          exerciseName: exercise.name,
          previousWeight: currentWeight,
          newWeight: currentWeight,
          passed: false,
          deloaded: false,
          message: 'Repeat ${_formatted(currentWeight)} ${progressionRule.unit} (failure $newFailureCount/${progressionRule.deloadAfterFailures})',
          newConsecutiveFailures: newFailureCount,
        );
      }
    }
  }

  /// Round a weight down to the nearest increment
  static double _roundToNearest(double value, {required double increment}) {
    if (increment <= 0) return value;
    return (value / increment).floorToDouble() * increment;
  }

  static String _formatted(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
