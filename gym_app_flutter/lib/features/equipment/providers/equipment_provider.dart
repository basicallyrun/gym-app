import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';

// Barbells provider
final barbellsProvider = StreamProvider<List<Barbell>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.barbells).watch();
});

// Plates provider
final platesProvider = StreamProvider<List<Plate>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.plates)
        ..orderBy([(t) => OrderingTerm.desc(t.weight)]))
      .watch();
});

// Dumbbell sets provider
final dumbbellSetsProvider = StreamProvider<List<DumbbellSet>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.dumbbellSets).watch();
});

// Machines provider
final machinesProvider = StreamProvider<List<Machine>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.machines).watch();
});

// Equipment notifier for CRUD operations
class EquipmentNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _database;

  EquipmentNotifier(this._database) : super(const AsyncValue.data(null));

  // Barbell operations
  Future<void> addBarbell(String name, double weight, String unit) async {
    state = const AsyncValue.loading();
    try {
      await _database.into(_database.barbells).insert(
            BarbellsCompanion.insert(
              name: name,
              weight: weight,
              unit: unit,
            ),
          );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBarbell(int id, String name, double weight, String unit, bool isDefault) async {
    state = const AsyncValue.loading();
    try {
      await (_database.update(_database.barbells)..where((tbl) => tbl.id.equals(id))).write(
        BarbellsCompanion(
          name: Value(name),
          weight: Value(weight),
          unit: Value(unit),
          isDefault: Value(isDefault),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBarbell(int id) async {
    state = const AsyncValue.loading();
    try {
      await (_database.delete(_database.barbells)..where((tbl) => tbl.id.equals(id))).go();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Plate operations
  Future<void> addPlate(double weight, String unit, int count, String color) async {
    state = const AsyncValue.loading();
    try {
      await _database.into(_database.plates).insert(
            PlatesCompanion.insert(
              weight: weight,
              unit: unit,
              count: count,
              color: Value(color),
            ),
          );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePlate(int id, double weight, String unit, int count, String color) async {
    state = const AsyncValue.loading();
    try {
      await (_database.update(_database.plates)..where((tbl) => tbl.id.equals(id))).write(
        PlatesCompanion(
          weight: Value(weight),
          unit: Value(unit),
          count: Value(count),
          color: Value(color),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePlate(int id) async {
    state = const AsyncValue.loading();
    try {
      await (_database.delete(_database.plates)..where((tbl) => tbl.id.equals(id))).go();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Machine operations
  Future<void> addMachine(String name, double minWeight, double maxWeight, double increment, String unit) async {
    state = const AsyncValue.loading();
    try {
      await _database.into(_database.machines).insert(
            MachinesCompanion.insert(
              name: name,
              minWeight: minWeight,
              maxWeight: maxWeight,
              increment: increment,
              unit: unit,
            ),
          );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateMachine(int id, String name, double minWeight, double maxWeight, double increment, String unit) async {
    state = const AsyncValue.loading();
    try {
      await (_database.update(_database.machines)..where((tbl) => tbl.id.equals(id))).write(
        MachinesCompanion(
          name: Value(name),
          minWeight: Value(minWeight),
          maxWeight: Value(maxWeight),
          increment: Value(increment),
          unit: Value(unit),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMachine(int id) async {
    state = const AsyncValue.loading();
    try {
      await (_database.delete(_database.machines)..where((tbl) => tbl.id.equals(id))).go();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final equipmentNotifierProvider = StateNotifierProvider<EquipmentNotifier, AsyncValue<void>>((ref) {
  final database = ref.watch(databaseProvider);
  return EquipmentNotifier(database);
});
