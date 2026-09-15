import '../../../core/database/database.dart';

class PlateLoadout {
  final List<PlateOnBar> platesPerSide;
  final double totalWeight;
  final bool isExact;
  final double difference; // 0 if exact, positive if under target

  const PlateLoadout({
    required this.platesPerSide,
    required this.totalWeight,
    required this.isExact,
    required this.difference,
  });
}

class PlateOnBar {
  final double weight;
  final String color;

  const PlateOnBar({
    required this.weight,
    required this.color,
  });
}

class PlateInventoryItem {
  final double weight;
  final String color;
  int pairsAvailable;

  PlateInventoryItem({
    required this.weight,
    required this.color,
    required this.pairsAvailable,
  });
}

/// Greedy largest-first plate calculation algorithm.
/// Returns exact plate list per side, or closest approximate with difference.
class PlateCalculator {
  static PlateLoadout calculate({
    required double targetWeight,
    required double barWeight,
    required List<Plate> availablePlates,
  }) {
    final remainingTotal = targetWeight - barWeight;

    if (remainingTotal < 0) {
      return PlateLoadout(
        platesPerSide: [],
        totalWeight: barWeight,
        isExact: false,
        difference: remainingTotal.abs(),
      );
    }

    var remainingPerSide = remainingTotal / 2.0;
    final List<PlateOnBar> platesPerSide = [];

    // Build a sorted list of plate denominations (largest first)
    // Each entry tracks how many are available (count / 2 = pairs available)
    final inventory = availablePlates
        .where((plate) => plate.count >= 2)
        .map((plate) => PlateInventoryItem(
              weight: plate.weight,
              color: plate.color,
              pairsAvailable: plate.count ~/ 2,
            ))
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    // Greedy algorithm: use largest plates first
    for (final item in inventory) {
      while (remainingPerSide >= item.weight && item.pairsAvailable > 0) {
        platesPerSide.add(PlateOnBar(
          weight: item.weight,
          color: item.color,
        ));
        remainingPerSide -= item.weight;
        item.pairsAvailable -= 1;
      }
    }

    final achievedPerSide = platesPerSide.fold(0.0, (sum, plate) => sum + plate.weight);
    final achievedTotal = barWeight + (achievedPerSide * 2.0);
    final isExact = remainingPerSide.abs() < 0.001;
    final difference = remainingPerSide * 2.0;

    return PlateLoadout(
      platesPerSide: platesPerSide,
      totalWeight: achievedTotal,
      isExact: isExact,
      difference: difference,
    );
  }

  /// Get standard plate color for common weights
  static String getPlateColor(double weight) {
    switch (weight) {
      case 45.0:
        return 'blue';
      case 35.0:
        return 'yellow';
      case 25.0:
        return 'green';
      case 10.0:
        return 'white';
      case 5.0:
        return 'red';
      case 2.5:
        return 'black';
      default:
        return 'gray';
    }
  }
}
