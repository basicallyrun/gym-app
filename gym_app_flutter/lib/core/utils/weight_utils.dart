/// Weight conversion utilities

const double lbToKgRatio = 0.45359237;
const double kgToLbRatio = 2.20462262;

/// Convert pounds to kilograms
double lbToKg(double lb) {
  return lb * lbToKgRatio;
}

/// Convert kilograms to pounds
double kgToLb(double kg) {
  return kg * kgToLbRatio;
}

/// Convert weight from one unit to another
double convertWeight(double weight, String fromUnit, String toUnit) {
  if (fromUnit == toUnit) return weight;

  if (fromUnit == 'lb' && toUnit == 'kg') {
    return lbToKg(weight);
  } else if (fromUnit == 'kg' && toUnit == 'lb') {
    return kgToLb(weight);
  }

  return weight;
}

/// Format weight with appropriate precision
String formatWeight(double weight, String unit) {
  // Use 1 decimal place for kg, whole numbers for lb (unless fractional)
  if (unit == 'kg') {
    return weight.toStringAsFixed(1);
  } else {
    // For lb, show decimal only if needed
    if (weight % 1 == 0) {
      return weight.toStringAsFixed(0);
    } else if (weight % 0.5 == 0) {
      return weight.toStringAsFixed(1);
    } else {
      return weight.toStringAsFixed(2);
    }
  }
}

/// Get default barbell weight for unit
double getDefaultBarbellWeight(String unit) {
  return unit == 'kg' ? 20.0 : 45.0;
}

/// Get default plate weights for unit
List<double> getDefaultPlateWeights(String unit) {
  if (unit == 'kg') {
    return [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25, 0.5];
  } else {
    return [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];
  }
}

/// Get default plate colors for weight
String getPlateColor(double weight, String unit) {
  if (unit == 'kg') {
    if (weight >= 25) return 'red';
    if (weight >= 20) return 'blue';
    if (weight >= 15) return 'yellow';
    if (weight >= 10) return 'green';
    if (weight >= 5) return 'white';
    if (weight >= 2.5) return 'red';
    if (weight >= 1.25) return 'green';
    return 'gray';
  } else {
    // lb colors
    if (weight >= 45) return 'red';
    if (weight >= 35) return 'yellow';
    if (weight >= 25) return 'green';
    if (weight >= 10) return 'white';
    if (weight >= 5) return 'red';
    if (weight >= 2.5) return 'blue';
    return 'gray';
  }
}
