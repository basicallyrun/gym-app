// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramTemplate _$ProgramTemplateFromJson(Map<String, dynamic> json) =>
    ProgramTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      goals: (json['goals'] as List<dynamic>).map((e) => e as String).toList(),
      experienceLevels: (json['experienceLevels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      daysPerWeek: (json['daysPerWeek'] as num).toInt(),
      estimatedSessionMinutes: (json['estimatedSessionMinutes'] as num).toInt(),
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      days: (json['days'] as List<dynamic>)
          .map((e) => ProgramDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgramTemplateToJson(ProgramTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'goals': instance.goals,
      'experienceLevels': instance.experienceLevels,
      'daysPerWeek': instance.daysPerWeek,
      'estimatedSessionMinutes': instance.estimatedSessionMinutes,
      'requiredEquipment': instance.requiredEquipment,
      'days': instance.days,
    };

ProgramDay _$ProgramDayFromJson(Map<String, dynamic> json) => ProgramDay(
  name: json['name'] as String,
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProgramDayToJson(ProgramDay instance) =>
    <String, dynamic>{'name': instance.name, 'exercises': instance.exercises};

ProgramExercise _$ProgramExerciseFromJson(Map<String, dynamic> json) =>
    ProgramExercise(
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as num).toInt(),
      repMin: (json['repMin'] as num).toInt(),
      repMax: (json['repMax'] as num).toInt(),
      restSeconds: (json['restSeconds'] as num).toInt(),
      equipmentType: json['equipmentType'] as String,
    );

Map<String, dynamic> _$ProgramExerciseToJson(ProgramExercise instance) =>
    <String, dynamic>{
      'exerciseName': instance.exerciseName,
      'sets': instance.sets,
      'repMin': instance.repMin,
      'repMax': instance.repMax,
      'restSeconds': instance.restSeconds,
      'equipmentType': instance.equipmentType,
    };
