import 'package:json_annotation/json_annotation.dart';

part 'program_template.g.dart';

@JsonSerializable()
class ProgramTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> goals;
  final List<String> experienceLevels;
  final int daysPerWeek;
  final int estimatedSessionMinutes;
  final List<String> requiredEquipment;
  final List<ProgramDay> days;

  ProgramTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.goals,
    required this.experienceLevels,
    required this.daysPerWeek,
    required this.estimatedSessionMinutes,
    required this.requiredEquipment,
    required this.days,
  });

  factory ProgramTemplate.fromJson(Map<String, dynamic> json) => _$ProgramTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramTemplateToJson(this);
}

@JsonSerializable()
class ProgramDay {
  final String name;
  final List<ProgramExercise> exercises;

  ProgramDay({
    required this.name,
    required this.exercises,
  });

  factory ProgramDay.fromJson(Map<String, dynamic> json) => _$ProgramDayFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramDayToJson(this);
}

@JsonSerializable()
class ProgramExercise {
  final String exerciseName;
  final int sets;
  final int repMin;
  final int repMax;
  final int restSeconds;
  final String equipmentType;

  ProgramExercise({
    required this.exerciseName,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.restSeconds,
    required this.equipmentType,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) => _$ProgramExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramExerciseToJson(this);
}
