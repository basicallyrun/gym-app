import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workout/presentation/widgets/plate_calculator_widget.dart';
import '../providers/settings_provider.dart';
import '../../equipment/presentation/equipment_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightUnit = ref.watch(weightUnitProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preferences Section
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.scale),
                  title: const Text('Weight Unit'),
                  subtitle: Text('Use ${weightUnit == 'kg' ? 'kilograms' : 'pounds'}'),
                  value: weightUnit == 'kg',
                  onChanged: (bool value) {
                    ref.read(settingsNotifierProvider.notifier)
                        .setWeightUnit(value ? 'kg' : 'lb');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
                  value: isDarkMode,
                  onChanged: (bool value) {
                    ref.read(settingsNotifierProvider.notifier).setDarkMode(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tools Section
          Text(
            'Tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Plate Calculator'),
              subtitle: const Text('Calculate barbell plate loading'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPlateCalculator(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Equipment'),
              subtitle: const Text('Manage barbells, plates, and machines'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EquipmentScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlateCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plate Calculator',
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
            const PlateCalculatorWidget(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
