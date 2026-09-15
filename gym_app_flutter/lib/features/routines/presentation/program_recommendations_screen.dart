import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';
import '../../../core/models/enums.dart';
import '../models/program_recommendation.dart';
import '../providers/program_generator_provider.dart';

class ProgramRecommendationsScreen extends ConsumerStatefulWidget {
  const ProgramRecommendationsScreen({super.key});

  @override
  ConsumerState<ProgramRecommendationsScreen> createState() => _ProgramRecommendationsScreenState();
}

class _ProgramRecommendationsScreenState extends ConsumerState<ProgramRecommendationsScreen> {
  List<ProgramRecommendation>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final recommendations = await ref.read(programGeneratorProvider.notifier).getRecommendations();
    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Recommendations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations == null || _recommendations!.isEmpty
              ? const Center(
                  child: Text('No matching programs found. Try adjusting your criteria.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recommendations!.length,
                  itemBuilder: (context, index) {
                    final recommendation = _recommendations![index];
                    return _RecommendationCard(
                      recommendation: recommendation,
                      rank: index + 1,
                      onImport: () => _importProgram(recommendation),
                    );
                  },
                ),
    );
  }

  Future<void> _importProgram(ProgramRecommendation recommendation) async {
    final database = ref.read(databaseProvider);
    final template = recommendation.template;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import ${template.name}?'),
        content: Text(
          'This will create a new routine with ${template.days.length} workout(s). You can customize it after import.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Create a routine for each day
      for (int dayIndex = 0; dayIndex < template.days.length; dayIndex++) {
        final day = template.days[dayIndex];

        // Create routine
        final routineId = await database.into(database.routines).insert(
              RoutinesCompanion.insert(
                name: '${template.name} - ${day.name}',
                source: drift.Value(template.id),
              ),
            );

        // Add exercises to routine
        for (int exIndex = 0; exIndex < day.exercises.length; exIndex++) {
          final programExercise = day.exercises[exIndex];

          // Find matching exercise in database
          final matchingExercises = await (database.select(database.exercises)
                ..where((e) => e.name.equals(programExercise.exerciseName)))
              .get();

          if (matchingExercises.isEmpty) continue;
          final exercise = matchingExercises.first;

          // Create routine exercise
          final routineExerciseId = await database.into(database.routineExercises).insert(
                RoutineExercisesCompanion.insert(
                  exerciseId: drift.Value(exercise.id),
                  routineId: routineId,
                  order: drift.Value(exIndex),
                  targetSets: drift.Value(programExercise.sets),
                  targetRepMin: drift.Value(programExercise.repMin),
                  targetRepMax: drift.Value(programExercise.repMax),
                  restSeconds: drift.Value(programExercise.restSeconds),
                ),
              );

          // Create default progression rule
          final progressionRuleId = await database.into(database.progressionRules).insert(
                ProgressionRulesCompanion.insert(
                  exerciseId: drift.Value(exercise.id),
                  incrementAmount: drift.Value(5.0), // Default increment
                  unit: 'lb',
                  triggerType: ProgressionTrigger.allSetsCompleted.name,
                  deloadAfterFailures: drift.Value(3),
                ),
              );

          // Link progression rule to routine exercise
          await (database.update(database.routineExercises)
                ..where((re) => re.id.equals(routineExerciseId)))
              .write(
            RoutineExercisesCompanion(
              progressionRuleId: drift.Value(progressionRuleId),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${template.name}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing program: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  final ProgramRecommendation recommendation;
  final int rank;
  final VoidCallback onImport;

  const _RecommendationCard({
    required this.recommendation,
    required this.rank,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final template = recommendation.template;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: rank == 1
              ? Colors.amber
              : rank == 2
                  ? Colors.grey.shade400
                  : Colors.orange.shade300,
          child: Text(
            '#$rank',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Score: ${recommendation.score.toStringAsFixed(0)} points',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${template.daysPerWeek} days/week • ${template.estimatedSessionMinutes} min sessions',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Why this program:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...recommendation.rationale.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(reason, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Text(
                  'Workouts:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...template.days.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        ...day.exercises.map((ex) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                            child: Text(
                              '${ex.exerciseName}: ${ex.sets}x${ex.repMin}${ex.repMin != ex.repMax ? '-${ex.repMax}' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.download),
                    label: const Text('Import Program'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
