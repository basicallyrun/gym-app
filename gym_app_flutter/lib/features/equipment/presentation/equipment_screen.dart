import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/database/database.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Barbells', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Plates', icon: Icon(Icons.trip_origin)),
            Tab(text: 'Machines', icon: Icon(Icons.settings_input_component)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BarbellsTab(),
          _PlatesTab(),
          _MachinesTab(),
        ],
      ),
    );
  }
}

// Barbells Tab
class _BarbellsTab extends ConsumerWidget {
  const _BarbellsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbellsAsync = ref.watch(barbellsProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    return barbellsAsync.when(
      data: (barbells) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: barbells.length + 1,
        itemBuilder: (context, index) {
          if (index == barbells.length) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Barbell'),
                onTap: () => _showBarbellDialog(context, ref, weightUnit),
              ),
            );
          }

          final barbell = barbells[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(barbell.name),
              subtitle: Text('${barbell.weight} ${barbell.unit}${barbell.isDefault ? ' • Default' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showBarbellDialog(context, ref, weightUnit, barbell: barbell),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(
                      context,
                      () => ref.read(equipmentNotifierProvider.notifier).deleteBarbell(barbell.id),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  void _showBarbellDialog(BuildContext context, WidgetRef ref, String weightUnit, {Barbell? barbell}) {
    final nameController = TextEditingController(text: barbell?.name ?? '');
    final weightController = TextEditingController(text: barbell?.weight.toString() ?? '');
    bool isDefault = barbell?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(barbell == null ? 'Add Barbell' : 'Edit Barbell'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: 'Weight ($weightUnit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set as default'),
                value: isDefault,
                onChanged: (value) {
                  setState(() {
                    isDefault = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final weight = double.tryParse(weightController.text);

                if (name.isEmpty || weight == null) return;

                if (barbell == null) {
                  await ref.read(equipmentNotifierProvider.notifier).addBarbell(name, weight, weightUnit);
                } else {
                  await ref.read(equipmentNotifierProvider.notifier).updateBarbell(
                        barbell.id,
                        name,
                        weight,
                        weightUnit,
                        isDefault,
                      );
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Plates Tab
class _PlatesTab extends ConsumerWidget {
  const _PlatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platesAsync = ref.watch(platesProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    return platesAsync.when(
      data: (plates) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plates.length + 1,
        itemBuilder: (context, index) {
          if (index == plates.length) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Plate'),
                onTap: () => _showPlateDialog(context, ref, weightUnit),
              ),
            );
          }

          final plate = plates[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorFromString(plate.color),
                radius: 12,
              ),
              title: Text('${plate.weight} ${plate.unit}'),
              subtitle: Text('${plate.count} pairs available'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showPlateDialog(context, ref, weightUnit, plate: plate),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(
                      context,
                      () => ref.read(equipmentNotifierProvider.notifier).deletePlate(plate.id),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _showPlateDialog(BuildContext context, WidgetRef ref, String weightUnit, {Plate? plate}) {
    final weightController = TextEditingController(text: plate?.weight.toString() ?? '');
    final countController = TextEditingController(text: plate?.count.toString() ?? '2');
    String selectedColor = plate?.color ?? 'gray';

    final colors = ['red', 'blue', 'yellow', 'green', 'white', 'black', 'gray'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(plate == null ? 'Add Plate' : 'Edit Plate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: 'Weight per plate ($weightUnit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: 'Pairs available'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedColor,
                decoration: const InputDecoration(labelText: 'Color'),
                items: colors
                    .map((color) => DropdownMenuItem(
                          value: color,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getColorFromString(color),
                                radius: 10,
                              ),
                              const SizedBox(width: 12),
                              Text(color[0].toUpperCase() + color.substring(1)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedColor = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                final count = int.tryParse(countController.text);

                if (weight == null || count == null) return;

                if (plate == null) {
                  await ref.read(equipmentNotifierProvider.notifier).addPlate(weight, weightUnit, count, selectedColor);
                } else {
                  await ref.read(equipmentNotifierProvider.notifier).updatePlate(
                        plate.id,
                        weight,
                        weightUnit,
                        count,
                        selectedColor,
                      );
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Machines Tab
class _MachinesTab extends ConsumerWidget {
  const _MachinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsync = ref.watch(machinesProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    return machinesAsync.when(
      data: (machines) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: machines.length + 1,
        itemBuilder: (context, index) {
          if (index == machines.length) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Machine'),
                onTap: () => _showMachineDialog(context, ref, weightUnit),
              ),
            );
          }

          final machine = machines[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: Text(machine.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showMachineDialog(context, ref, weightUnit, machine: machine),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(
                      context,
                      () => ref.read(equipmentNotifierProvider.notifier).deleteMachine(machine.id),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  void _showMachineDialog(BuildContext context, WidgetRef ref, String weightUnit, {Machine? machine}) {
    final nameController = TextEditingController(text: machine?.name ?? '');
    final minWeightController = TextEditingController(text: machine?.minWeight.toString() ?? '0');
    final maxWeightController = TextEditingController(text: machine?.maxWeight.toString() ?? '200');
    final incrementController = TextEditingController(text: machine?.increment.toString() ?? '5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(machine == null ? 'Add Machine' : 'Edit Machine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Machine Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minWeightController,
                decoration: InputDecoration(labelText: 'Min Weight ($weightUnit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxWeightController,
                decoration: InputDecoration(labelText: 'Max Weight ($weightUnit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: incrementController,
                decoration: InputDecoration(labelText: 'Weight Increment ($weightUnit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final name = nameController.text;
              final minWeight = double.tryParse(minWeightController.text);
              final maxWeight = double.tryParse(maxWeightController.text);
              final increment = double.tryParse(incrementController.text);

              if (name.isEmpty || minWeight == null || maxWeight == null || increment == null) return;

              if (machine == null) {
                await ref.read(equipmentNotifierProvider.notifier).addMachine(
                      name,
                      minWeight,
                      maxWeight,
                      increment,
                      weightUnit,
                    );
              } else {
                await ref.read(equipmentNotifierProvider.notifier).updateMachine(
                      machine.id,
                      name,
                      minWeight,
                      maxWeight,
                      increment,
                      weightUnit,
                    );
              }

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

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
