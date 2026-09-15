import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../../core/database/providers.dart';
import '../../../core/database/database.dart';
import '../../settings/providers/settings_provider.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    if (!workoutState.isWorkoutActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No active workout')),
      );
    }

    final currentExercise = workoutState.currentRoutineExercise;
    if (currentExercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No exercise selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context, ref),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _showFinishDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: workoutState.totalSetsCount > 0
                ? workoutState.completedSetsCount / workoutState.totalSetsCount
                : 0,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercise ${workoutState.currentExerciseIndex + 1} of ${workoutState.totalExercises}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${workoutState.completedSetsCount}/${workoutState.totalSetsCount} sets',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exercise Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: workoutState.currentExerciseIndex > 0
                      ? () => ref.read(workoutProvider.notifier).previousExercise()
                      : null,
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _getExerciseName(ref, currentExercise.exerciseId),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Loading...',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: workoutState.currentExerciseIndex < workoutState.totalExercises - 1
                      ? () => ref.read(workoutProvider.notifier).nextExercise()
                      : null,
                ),
              ],
            ),
          ),

          // Rest Timer
          if (workoutState.isRestTimerRunning) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rest: ${_formatTime(workoutState.restTimeRemaining)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => ref.read(workoutProvider.notifier).extendRestTimer(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => ref.read(workoutProvider.notifier).stopRestTimer(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sets List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: workoutState.currentSetLogs.length,
              itemBuilder: (context, index) {
                final setLog = workoutState.currentSetLogs[index];
                return SetRowWidget(
                  setLog: setLog,
                  setNumber: index + 1,
                  weightUnit: weightUnit,
                );
              },
            ),
          ),

          // Weight Adjustment Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSetAllWeightsDialog(context, ref, weightUnit),
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Set All Weights'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getExerciseName(WidgetRef ref, int? exerciseId) async {
    if (exerciseId == null) return null;
    final database = ref.read(databaseProvider);
    final exercise = await (database.select(database.exercises)..where((e) => e.id.equals(exerciseId))).getSingle();
    return exercise.name;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSetAllWeightsDialog(BuildContext context, WidgetRef ref, String weightUnit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Weight for All Sets'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Weight ($weightUnit)',
            suffixText: weightUnit,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                await ref.read(workoutProvider.notifier).setWeightForAllSets(weight);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(workoutProvider.notifier).finishWorkout();
              if (context.mounted) {
                Navigator.of(context).pop();
                _showProgressionResults(context, ref);
              }
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _showProgressionResults(BuildContext context, WidgetRef ref) {
    final progressionResults = ref.read(workoutProvider).progressionResults;

    if (progressionResults.isEmpty) {
      context.go('/');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete! 🎉'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progression Updates:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...progressionResults.map((result) {
                final icon = result.passed
                    ? '✅'
                    : result.deloaded
                        ? '⬇️'
                        : '🔁';
                final color = result.passed
                    ? Colors.green
                    : result.deloaded
                        ? Colors.orange
                        : Colors.blue;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                result.exerciseName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.message,
                          style: TextStyle(color: color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout'),
        content: const Text('Are you sure you want to cancel this workout? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(workoutProvider.notifier).cancelWorkout();
              if (context.mounted) {
                Navigator.of(context).pop();
                context.go('/');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );
  }
}

class SetRowWidget extends ConsumerStatefulWidget {
  final SetLog setLog;
  final int setNumber;
  final String weightUnit;

  const SetRowWidget({
    required this.setLog,
    required this.setNumber,
    required this.weightUnit,
    super.key,
  });

  @override
  ConsumerState<SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends ConsumerState<SetRowWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setLog.targetWeight > 0 ? widget.setLog.targetWeight.toString() : '',
    );
    _repsController = TextEditingController(
      text: widget.setLog.actualReps > 0 ? widget.setLog.actualReps.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setLog.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCompleted ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Set number
            CircleAvatar(
              radius: 16,
              backgroundColor: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              child: Text(
                '${widget.setNumber}',
                style: TextStyle(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Weight input
            Expanded(
              child: TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight',
                  suffixText: widget.weightUnit,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !isCompleted,
              ),
            ),
            const SizedBox(width: 8),

            // Reps input
            SizedBox(
              width: 80,
              child: TextField(
                controller: _repsController,
                decoration: InputDecoration(
                  labelText: 'Reps',
                  hintText: '${widget.setLog.targetReps}',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                enabled: !isCompleted,
              ),
            ),
            const SizedBox(width: 8),

            // Complete button
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () async {
                if (isCompleted) {
                  await ref.read(workoutProvider.notifier).uncompleteSet(widget.setLog);
                } else {
                  final weight = double.tryParse(_weightController.text) ?? 0;
                  final reps = int.tryParse(_repsController.text) ?? widget.setLog.targetReps;
                  await ref.read(workoutProvider.notifier).completeSet(widget.setLog, reps, weight);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
