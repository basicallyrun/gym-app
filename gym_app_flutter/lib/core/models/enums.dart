enum WeightUnit {
  lb,
  kg;

  String get abbreviation => name;

  double convert(double value, WeightUnit target) {
    if (this == target) return value;
    switch ((this, target)) {
      case (WeightUnit.lb, WeightUnit.kg):
        return value * 0.453592;
      case (WeightUnit.kg, WeightUnit.lb):
        return value / 0.453592;
      default:
        return value;
    }
  }
}

enum ExerciseCategory {
  compound,
  isolation,
  cardio;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,
  forearms;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum EquipmentType {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  other;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum ProgressionTrigger {
  allSetsCompleted,
  topSetHit;

  String get displayName {
    switch (this) {
      case ProgressionTrigger.allSetsCompleted:
        return 'All Sets Completed';
      case ProgressionTrigger.topSetHit:
        return 'Top Set Hit';
    }
  }
}

enum Goal {
  strength,
  hypertrophy,
  generalFitness,
  powerlifting,
  athleticPerformance;

  String get displayName {
    switch (this) {
      case Goal.strength:
        return 'Strength';
      case Goal.hypertrophy:
        return 'Hypertrophy';
      case Goal.generalFitness:
        return 'General Fitness';
      case Goal.powerlifting:
        return 'Powerlifting';
      case Goal.athleticPerformance:
        return 'Athletic Performance';
    }
  }
}

enum Experience {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum SessionDuration {
  thirty(30),
  fortyFive(45),
  sixty(60),
  seventyFive(75),
  ninety(90);

  final int minutes;
  const SessionDuration(this.minutes);

  String get displayName => '$minutes min';
}

// Extension to convert enum to/from string for drift
extension WeightUnitX on WeightUnit {
  static WeightUnit fromString(String value) {
    return WeightUnit.values.firstWhere((e) => e.name == value);
  }

  String toDbString() => name;
}

extension ExerciseCategoryX on ExerciseCategory {
  static ExerciseCategory fromString(String value) {
    return ExerciseCategory.values.firstWhere((e) => e.name == value);
  }

  String toDbString() => name;
}

extension MuscleGroupX on MuscleGroup {
  static MuscleGroup fromString(String value) {
    return MuscleGroup.values.firstWhere((e) => e.name == value);
  }

  String toDbString() => name;
}

extension EquipmentTypeX on EquipmentType {
  static EquipmentType fromString(String value) {
    return EquipmentType.values.firstWhere((e) => e.name == value);
  }

  String toDbString() => name;
}

extension ProgressionTriggerX on ProgressionTrigger {
  static ProgressionTrigger fromString(String value) {
    return ProgressionTrigger.values.firstWhere((e) => e.name == value);
  }

  String toDbString() => name;
}
