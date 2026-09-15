import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';
import '../../../core/database/providers.dart';

// Settings provider - fetches current settings
final settingsProvider = StreamProvider<Setting?>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.settings).watchSingleOrNull();
});

// Weight unit provider - extracts just the unit
final weightUnitProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.when(
    data: (setting) => setting?.weightUnit ?? 'lb',
    loading: () => 'lb',
    error: (_, __) => 'lb',
  );
});

// Dark mode provider
final darkModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.when(
    data: (setting) => setting?.isDarkMode ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Settings notifier for updates
class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _database;

  SettingsNotifier(this._database) : super(const AsyncValue.data(null));

  Future<void> setWeightUnit(String unit) async {
    state = const AsyncValue.loading();
    try {
      // Get current settings
      final currentSettings = await _database.select(_database.settings).getSingleOrNull();

      if (currentSettings != null) {
        // Update existing
        await (_database.update(_database.settings)
              ..where((tbl) => tbl.id.equals(currentSettings.id)))
            .write(SettingsCompanion(
              weightUnit: Value(unit),
            ));
      } else {
        // Insert new
        await _database.into(_database.settings).insert(
          SettingsCompanion.insert(
            weightUnit: Value(unit),
          ),
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    state = const AsyncValue.loading();
    try {
      final currentSettings = await _database.select(_database.settings).getSingleOrNull();

      if (currentSettings != null) {
        await (_database.update(_database.settings)
              ..where((tbl) => tbl.id.equals(currentSettings.id)))
            .write(SettingsCompanion(
              isDarkMode: Value(enabled),
            ));
      } else {
        await _database.into(_database.settings).insert(
          SettingsCompanion.insert(
            isDarkMode: Value(enabled),
          ),
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  final database = ref.watch(databaseProvider);
  return SettingsNotifier(database);
});
