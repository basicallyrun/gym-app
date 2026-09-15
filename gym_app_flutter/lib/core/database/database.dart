import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/enums.dart';

part 'database.g.dart';

// Exercises table
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get muscleGroups => text()(); // JSON array as string
  TextColumn get equipmentType => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

// Barbells table
class Barbells extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get weight => real()();
  TextColumn get unit => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

// Plates table
class Plates extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weight => real()();
  TextColumn get unit => text()();
  IntColumn get count => integer()();
  TextColumn get color => text().withDefault(const Constant('gray'))();
}

// DumbbellSets table
class DumbbellSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get availableWeights => text()(); // JSON array as string
  TextColumn get unit => text()();
}

// Machines table
class Machines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get minWeight => real()();
  RealColumn get maxWeight => real()();
  RealColumn get increment => real()();
  TextColumn get unit => text()();
}

// CableAttachments table
class CableAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// Routines table
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// RoutineExercises table (junction table with additional fields)
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().nullable().references(Exercises, #id, onDelete: KeyAction.setNull)();
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get order => integer().withDefault(const Constant(0))();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetRepMin => integer().withDefault(const Constant(5))();
  IntColumn get targetRepMax => integer().withDefault(const Constant(5))();
  RealColumn get targetRPE => real().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  RealColumn get defaultWeight => real().withDefault(const Constant(0.0))();
  IntColumn get progressionRuleId => integer().nullable().references(ProgressionRules, #id, onDelete: KeyAction.setNull)();
}

// WorkoutSessions table
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().nullable().references(Routines, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// SetLogs table
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().nullable().references(Exercises, #id, onDelete: KeyAction.setNull)();
  IntColumn get setNumber => integer()();
  RealColumn get targetWeight => real()();
  RealColumn get actualWeight => real()();
  IntColumn get targetReps => integer()();
  IntColumn get actualReps => integer()();
  TextColumn get unit => text()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// ProgressionRules table
class ProgressionRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().nullable().references(Exercises, #id, onDelete: KeyAction.setNull)();
  RealColumn get incrementAmount => real().withDefault(const Constant(5.0))();
  TextColumn get unit => text()();
  TextColumn get triggerType => text()();
  IntColumn get consecutiveFailures => integer().withDefault(const Constant(0))();
  RealColumn get deloadPercentage => real().withDefault(const Constant(0.10))();
  IntColumn get deloadAfterFailures => integer().withDefault(const Constant(3))();
}

// Settings table (single row for user preferences)
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get weightUnit => text().withDefault(const Constant('lb'))();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [
  Exercises,
  Barbells,
  Plates,
  DumbbellSets,
  Machines,
  CableAttachments,
  Routines,
  RoutineExercises,
  WorkoutSessions,
  SetLogs,
  ProgressionRules,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;

  // Private constructor
  AppDatabase._internal() : super(_openConnection());

  // Factory constructor to return singleton
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default settings row
        await into(settings).insert(
          SettingsCompanion.insert(
            weightUnit: const Value('lb'),
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add defaultWeight column to RoutineExercises
          await m.addColumn(routineExercises, routineExercises.defaultWeight);
        }
        if (from < 3) {
          // Add Settings table
          await m.createTable(settings);
          // Insert default settings row
          await into(settings).insert(
            SettingsCompanion.insert(
              weightUnit: const Value('lb'),
            ),
          );
        }
      },
    );
  }

  // Helper method to parse JSON arrays for muscle groups
  static List<String> parseMuscleGroups(String json) {
    return (jsonDecode(json) as List).map((e) => e.toString()).toList();
  }

  // Helper method to encode JSON arrays for muscle groups
  static String encodeMuscleGroups(List<String> groups) {
    return jsonEncode(groups);
  }

  // Helper method to parse JSON arrays for available weights
  static List<double> parseAvailableWeights(String json) {
    return (jsonDecode(json) as List).map((e) => (e as num).toDouble()).toList();
  }

  // Helper method to encode JSON arrays for available weights
  static String encodeAvailableWeights(List<double> weights) {
    return jsonEncode(weights);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gym_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
