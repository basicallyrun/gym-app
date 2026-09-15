import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/routine_provider.dart';
import '../../workout/providers/workout_provider.dart';

class RoutineDetailScreen extends ConsumerWidget {
  final int routineId;

  const RoutineDetailScreen({
    required this.routineId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineDetailProvider(routineId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit routine name
            },
          ),
        ],
      ),
      body: routineAsync.when(
        data: (routineData) {
          if (routineData == null) {
            return const Center(child: Text('Routine not found'));
          }

          final routine = routineData.routine;
          final routineExercises = routineData.routineExercises;
          final exercises = routineData.exercises;

          if (routineExercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add exercises to your routine',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showExercisePicker(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        routine.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Start workout
                        final workoutNotifier = ref.read(workoutProvider.notifier);
                        workoutNotifier.startWorkout(routineId);
                        context.push('/workout');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routineExercises.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) {
                      newIndex--;
                    }
                    final reordered = List<int>.from(
                      routineExercises.map((re) => re.id),
                    );
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);

                    final service = ref.read(routineServiceProvider);
                    await service.reorderRoutineExercises(routineId, reordered);
                    ref.invalidate(routineDetailProvider(routineId));
                  },
                  itemBuilder: (context, index) {
                    final routineExercise = routineExercises[index];
                    final exercise = exercises.firstWhere(
                      (e) => e.id == routineExercise.exerciseId,
                    );

                    return Card(
                      key: ValueKey(routineExercise.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(
                          '${routineExercise.targetSets} sets × ${_formatReps(routineExercise)} reps | ${_formatRest(routineExercise.restSeconds)} rest',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditExerciseDialog(
                                context,
                                ref,
                                routineExercise,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmRemoveExercise(
                                context,
                                ref,
                                routineExercise.id,
                              ),
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExercisePicker(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatReps(dynamic re) {
    if (re.targetRepMin == re.targetRepMax) {
      return '${re.targetRepMin}';
    }
    return '${re.targetRepMin}-${re.targetRepMax}';
  }

  String _formatRest(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  void _showExercisePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExercisePickerSheet(routineId: routineId),
    );
  }

  void _showEditExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic routineExercise,
  ) {
    final setsController = TextEditingController(text: routineExercise.targetSets.toString());
    final repMinController = TextEditingController(text: routineExercise.targetRepMin.toString());
    final repMaxController = TextEditingController(text: routineExercise.targetRepMax.toString());
    final restSecondsController = TextEditingController(text: routineExercise.restSeconds.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Target Sets'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repMinController,
                decoration: const InputDecoration(labelText: 'Min Reps'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repMaxController,
                decoration: const InputDecoration(labelText: 'Max Reps'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: restSecondsController,
                decoration: const InputDecoration(labelText: 'Rest (seconds)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(routineServiceProvider);
              await service.updateRoutineExercise(
                routineExerciseId: routineExercise.id,
                targetSets: int.tryParse(setsController.text),
                targetRepMin: int.tryParse(repMinController.text),
                targetRepMax: int.tryParse(repMaxController.text),
                restSeconds: int.tryParse(restSecondsController.text),
              );
              ref.invalidate(routineDetailProvider(routineId));
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveExercise(BuildContext context, WidgetRef ref, int routineExerciseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: const Text('Remove this exercise from the routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(routineServiceProvider);
              await service.removeExerciseFromRoutine(routineExerciseId);
              ref.invalidate(routineDetailProvider(routineId));
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final int routineId;

  const ExercisePickerSheet({
    required this.routineId,
    super.key,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Exercise',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) {
                  final filtered = exercises.where((e) {
                    return _searchQuery.isEmpty || e.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(exercise.equipmentType),
                        onTap: () async {
                          final service = ref.read(routineServiceProvider);
                          final routineData = await ref.read(routineDetailProvider(widget.routineId).future);
                          final nextOrder = routineData?.routineExercises.length ?? 0;

                          await service.addExerciseToRoutine(
                            routineId: widget.routineId,
                            exerciseId: exercise.id,
                            order: nextOrder,
                          );
                          ref.invalidate(routineDetailProvider(widget.routineId));
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}
