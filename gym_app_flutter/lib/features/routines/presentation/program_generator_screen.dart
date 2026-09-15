import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../models/questionnaire.dart';
import '../providers/program_generator_provider.dart';
import 'program_recommendations_screen.dart';

class ProgramGeneratorScreen extends ConsumerStatefulWidget {
  const ProgramGeneratorScreen({super.key});

  @override
  ConsumerState<ProgramGeneratorScreen> createState() => _ProgramGeneratorScreenState();
}

class _ProgramGeneratorScreenState extends ConsumerState<ProgramGeneratorScreen> {
  int _currentStep = 0;
  Goal _goal = Goal.strength;
  Experience _experience = Experience.beginner;
  int _daysPerWeek = 3;
  Set<EquipmentType> _availableEquipment = {EquipmentType.barbell, EquipmentType.dumbbell};
  SessionDuration _sessionDuration = SessionDuration.sixty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Generator'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _generateRecommendations();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? 'Get Recommendations' : 'Continue'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Goal'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What is your primary training goal?'),
                const SizedBox(height: 12),
                ...Goal.values.map((goal) {
                  return RadioListTile<Goal>(
                    title: Text(goal.displayName),
                    value: goal,
                    groupValue: _goal,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _goal = value);
                      }
                    },
                  );
                }).toList(),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Experience'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What is your training experience level?'),
                const SizedBox(height: 12),
                ...Experience.values.map((exp) {
                  return RadioListTile<Experience>(
                    title: Text(exp.displayName),
                    value: exp,
                    groupValue: _experience,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _experience = value);
                      }
                    },
                  );
                }).toList(),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Frequency'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How many days per week can you train?'),
                const SizedBox(height: 12),
                ...[3, 4, 5, 6].map((days) {
                  return RadioListTile<int>(
                    title: Text('$days days per week'),
                    value: days,
                    groupValue: _daysPerWeek,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _daysPerWeek = value);
                      }
                    },
                  );
                }).toList(),
              ],
            ),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Equipment'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What equipment do you have access to?'),
                const SizedBox(height: 12),
                ...EquipmentType.values.where((eq) => eq != EquipmentType.other).map((equipment) {
                  return CheckboxListTile(
                    title: Text(equipment.displayName),
                    value: _availableEquipment.contains(equipment),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _availableEquipment.add(equipment);
                        } else {
                          _availableEquipment.remove(equipment);
                        }
                      });
                    },
                  );
                }).toList(),
              ],
            ),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Session Duration'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How long do you have per workout session?'),
                const SizedBox(height: 12),
                ...SessionDuration.values.map((duration) {
                  return RadioListTile<SessionDuration>(
                    title: Text(duration.displayName),
                    value: duration,
                    groupValue: _sessionDuration,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sessionDuration = value);
                      }
                    },
                  );
                }).toList(),
              ],
            ),
            isActive: _currentStep >= 4,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  Future<void> _generateRecommendations() async {
    final questionnaire = Questionnaire(
      goal: _goal,
      experience: _experience,
      daysPerWeek: _daysPerWeek,
      availableEquipment: _availableEquipment,
      sessionDuration: _sessionDuration,
    );

    ref.read(programGeneratorProvider.notifier).updateQuestionnaire(questionnaire);

    // Navigate to recommendations screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProgramRecommendationsScreen(),
        ),
      );
    }
  }
}
