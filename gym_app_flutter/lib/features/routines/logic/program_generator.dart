import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/models/enums.dart';
import '../models/questionnaire.dart';
import '../models/program_template.dart';
import '../models/program_recommendation.dart';

class ProgramGenerator {
  /// Load program templates from bundled JSON files.
  static Future<List<ProgramTemplate>> loadTemplates() async {
    const templateNames = [
      'starting_strength',
      'ppl',
      'upper_lower',
      'full_body_3x',
      'five_three_one',
    ];

    print('Loading ${templateNames.length} program templates...');
    final templates = <ProgramTemplate>[];
    for (final name in templateNames) {
      try {
        final jsonString = await rootBundle.loadString('assets/data/templates/$name.json');
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final template = ProgramTemplate.fromJson(jsonData);
        templates.add(template);
        print('Successfully loaded template: ${template.name}');
      } catch (e) {
        // Skip templates that fail to load
        print('Failed to load template $name: $e');
      }
    }
    print('Loaded ${templates.length} templates total');
    return templates;
  }

  /// Filter and score templates based on questionnaire answers.
  /// Returns ranked recommendations (top 3).
  static Future<List<ProgramRecommendation>> recommend(Questionnaire questionnaire) async {
    final templates = await loadTemplates();
    final recommendations = <ProgramRecommendation>[];

    print('Questionnaire: goal=${questionnaire.goal.name}, experience=${questionnaire.experience.name}, days=${questionnaire.daysPerWeek}');

    for (final template in templates) {
      double score = 0;
      final rationale = <String>[];

      print('Evaluating ${template.name}: goals=${template.goals}, experience=${template.experienceLevels}, days=${template.daysPerWeek}');

      // 1. Filter by experience level
      final experienceMatch = template.experienceLevels.contains(questionnaire.experience.name);
      print('  Experience match: $experienceMatch');
      if (!experienceMatch) continue;

      // 2. Filter by goal compatibility
      final goalMatch = template.goals.contains(questionnaire.goal.name);
      print('  Goal match: $goalMatch');
      if (goalMatch) {
        score += 30;
        rationale.add('Matches your ${questionnaire.goal.displayName} goal');
      } else {
        continue;
      }

      // 3. Days per week compatibility
      final daysDiff = (template.daysPerWeek - questionnaire.daysPerWeek).abs();
      if (daysDiff == 0) {
        score += 25;
        rationale.add('Exactly ${questionnaire.daysPerWeek} days/week as requested');
      } else if (daysDiff == 1) {
        score += 10;
        rationale.add('Close match: ${template.daysPerWeek} days/week (you wanted ${questionnaire.daysPerWeek})');
      } else {
        continue; // Too far off on days
      }

      // 4. Session duration compatibility
      final durationDiff = (template.estimatedSessionMinutes - questionnaire.sessionDuration.minutes).abs();
      if (durationDiff <= 15) {
        score += 20;
        rationale.add('Fits within your time budget');
      } else if (durationDiff <= 30) {
        score += 5;
        rationale.add('May slightly exceed your time budget');
      }

      // 5. Equipment availability scoring
      final requiredTypes = template.requiredEquipment
          .map((eq) {
            try {
              return EquipmentType.values.firstWhere((e) => e.name == eq);
            } catch (e) {
              return null;
            }
          })
          .whereType<EquipmentType>()
          .toSet();

      final availableTypes = questionnaire.availableEquipment;
      final missingEquipment = requiredTypes.difference(availableTypes);

      if (missingEquipment.isEmpty) {
        score += 25;
        rationale.add('All required equipment available');
      } else {
        final penalty = missingEquipment.length * 10.0;
        score -= penalty;
        final missingNames = missingEquipment.map((e) => e.displayName).join(', ');
        rationale.add('Missing equipment: $missingNames');
      }

      // 6. Penalize if movements to avoid overlap with template exercises
      if (questionnaire.movementsToAvoid.isNotEmpty) {
        final allExercises = template.days
            .expand((day) => day.exercises)
            .map((ex) => ex.exerciseName.toLowerCase())
            .toList();
        final avoided = questionnaire.movementsToAvoid.map((m) => m.toLowerCase()).toList();
        final conflicts = allExercises.where((exercise) {
          return avoided.any((avoid) => exercise.contains(avoid));
        }).toList();

        if (conflicts.isNotEmpty) {
          score -= conflicts.length * 5.0;
          rationale.add('Contains ${conflicts.length} exercise(s) you may want to substitute');
        }
      }

      recommendations.add(ProgramRecommendation(
        template: template,
        score: score,
        rationale: rationale,
      ));
    }

    // Sort by score and return top 3
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    print('Found ${recommendations.length} matching programs');
    for (final rec in recommendations.take(3)) {
      print('  - ${rec.template.name}: ${rec.score} points');
    }
    return recommendations.take(3).toList();
  }
}
