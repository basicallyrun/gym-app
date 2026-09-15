import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../core/database/database.dart';
import '../core/models/enums.dart';

class SeedingService {
  final AppDatabase database;

  SeedingService(this.database);

  Future<void> seedInitialData() async {
    // Check if already seeded
    final exerciseCount = await database.select(database.exercises).get();
    if (exerciseCount.isNotEmpty) {
      return; // Already seeded
    }

    // Seed exercises
    await _seedExercises();

    // Seed default equipment
    await _seedDefaultEquipment();
  }

  Future<void> _seedExercises() async {
    final jsonString = await rootBundle.loadString('assets/data/exercise_library.json');
    final List<dynamic> exerciseData = jsonDecode(jsonString);

    for (final exerciseJson in exerciseData) {
      final muscleGroups = (exerciseJson['muscleGroups'] as List)
          .map((e) => e.toString())
          .toList();

      await database.into(database.exercises).insert(
        ExercisesCompanion.insert(
          name: exerciseJson['name'] as String,
          category: exerciseJson['category'] as String,
          muscleGroups: jsonEncode(muscleGroups),
          equipmentType: exerciseJson['equipmentType'] as String,
          notes: Value(exerciseJson['notes'] as String? ?? ''),
          isCustom: const Value(false),
        ),
      );
    }
  }

  Future<void> _seedDefaultEquipment() async {
    // Default barbell - 45 lb Olympic bar
    await database.into(database.barbells).insert(
      BarbellsCompanion.insert(
        name: '45 lb Olympic Barbell',
        weight: 45.0,
        unit: WeightUnit.lb.name,
        isDefault: const Value(true),
      ),
    );

    // Default plates
    final defaultPlates = [
      {'weight': 45.0, 'count': 4, 'color': 'blue'},
      {'weight': 35.0, 'count': 2, 'color': 'yellow'},
      {'weight': 25.0, 'count': 2, 'color': 'green'},
      {'weight': 10.0, 'count': 4, 'color': 'white'},
      {'weight': 5.0, 'count': 4, 'color': 'red'},
      {'weight': 2.5, 'count': 4, 'color': 'black'},
    ];

    for (final plate in defaultPlates) {
      await database.into(database.plates).insert(
        PlatesCompanion.insert(
          weight: plate['weight'] as double,
          unit: WeightUnit.lb.name,
          count: plate['count'] as int,
          color: Value(plate['color'] as String),
        ),
      );
    }
  }
}
