import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import 'exercise_progress_screen.dart';
import '../../settings/providers/settings_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workout history yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first workout to see it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final duration = session.endTime != null
                  ? session.endTime!.difference(session.startTime)
                  : Duration.zero;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(_formatDate(session.startTime)),
                  subtitle: Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showWorkoutDetail(context, ref, session.id, weightUnit);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading history: $err'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today - ${DateFormat('h:mm a').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday - ${DateFormat('h:mm a').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)} - ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, y - h:mm a').format(date);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    return '${remainingMinutes}m';
  }

  void _showWorkoutDetail(BuildContext context, WidgetRef ref, int sessionId, String weightUnit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return WorkoutDetailSheet(
            sessionId: sessionId,
            scrollController: scrollController,
            weightUnit: weightUnit,
          );
        },
      ),
    );
  }
}

class WorkoutDetailSheet extends ConsumerWidget {
  final int sessionId;
  final ScrollController scrollController;
  final String weightUnit;

  const WorkoutDetailSheet({
    required this.sessionId,
    required this.scrollController,
    required this.weightUnit,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutDetailProvider(sessionId));

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return const Center(child: Text('Workout not found'));
        }

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
                          'Workout Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${detail.totalSets} sets',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.show_chart,
                        label: '${detail.totalVolume.toStringAsFixed(0)} $weightUnit',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: detail.exerciseGroups.length,
                itemBuilder: (context, index) {
                  final exerciseId = detail.exerciseGroups.keys.elementAt(index);
                  final sets = detail.exerciseGroups[exerciseId]!;
                  final exercise = detail.exercises[exerciseId];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: exercise != null
                          ? () {
                              Navigator.of(context).pop(); // Close modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ExerciseProgressScreen(
                                    exerciseId: exerciseId!,
                                    exerciseName: exercise.name,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise?.name ?? 'Unknown Exercise',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.show_chart,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          ...sets.map((setLog) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      'Set ${setLog.setNumber}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${setLog.actualWeight} $weightUnit × ${setLog.actualReps} reps',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
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
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
