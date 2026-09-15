import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/providers.dart';
import '../../logic/plate_calculator.dart';

class PlateCalculatorWidget extends ConsumerStatefulWidget {
  final double? initialWeight;

  const PlateCalculatorWidget({
    this.initialWeight,
    super.key,
  });

  @override
  ConsumerState<PlateCalculatorWidget> createState() => _PlateCalculatorWidgetState();
}

class _PlateCalculatorWidgetState extends ConsumerState<PlateCalculatorWidget> {
  late TextEditingController _weightController;
  PlateLoadout? _loadout;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    if (widget.initialWeight != null) {
      _calculate();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final targetWeight = double.tryParse(_weightController.text);
    if (targetWeight == null || targetWeight <= 0) {
      setState(() {
        _loadout = null;
      });
      return;
    }

    final database = ref.read(databaseProvider);

    // Get default barbell
    final barbells = await (database.select(database.barbells)
          ..where((b) => b.isDefault.equals(true))
          ..limit(1))
        .get();

    final barbell = barbells.isNotEmpty
        ? barbells.first
        : Barbell(
            id: 0,
            name: 'Default',
            weight: 45.0,
            unit: 'lb',
            isDefault: true,
          );

    // Get available plates
    final plates = await database.select(database.plates).get();

    final loadout = PlateCalculator.calculate(
      targetWeight: targetWeight,
      barWeight: barbell.weight,
      availablePlates: plates,
    );

    setState(() {
      _loadout = loadout;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plate Calculator',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Target Weight',
                  suffixText: 'lbs',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadout != null) ...[
          if (!_loadout!.isExact)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cannot load exact weight. '
                      '${_loadout!.difference > 0 ? "Missing ${_loadout!.difference.toStringAsFixed(1)} lbs" : ""}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_loadout!.totalWeight.toStringAsFixed(1)} lbs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (_loadout!.isExact)
                        const Chip(
                          label: Text('Exact'),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadout!.platesPerSide.isEmpty)
                    const Text('No plates needed (bar only)')
                  else ...[
                    Text(
                      'Per Side:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _loadout!.platesPerSide.map((plate) {
                        return _PlateChip(
                          weight: plate.weight,
                          color: plate.color,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlateChip extends StatelessWidget {
  final double weight;
  final String color;

  const _PlateChip({
    required this.weight,
    required this.color,
  });

  Color get chipColor {
    switch (color) {
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'green':
        return Colors.green;
      case 'white':
        return Colors.grey.shade300;
      case 'red':
        return Colors.red;
      case 'black':
        return Colors.black87;
      case 'gray':
      default:
        return Colors.grey;
    }
  }

  Color get textColor {
    switch (color) {
      case 'white':
      case 'yellow':
      case 'gray':
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${weight.toStringAsFixed(weight == weight.toInt() ? 0 : 1)} lb',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
