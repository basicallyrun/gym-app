import '../../../core/models/enums.dart';

class Questionnaire {
  final Goal goal;
  final Experience experience;
  final int daysPerWeek;
  final Set<EquipmentType> availableEquipment;
  final SessionDuration sessionDuration;
  final List<String> movementsToAvoid;

  const Questionnaire({
    this.goal = Goal.strength,
    this.experience = Experience.beginner,
    this.daysPerWeek = 3,
    this.availableEquipment = const {EquipmentType.barbell, EquipmentType.dumbbell},
    this.sessionDuration = SessionDuration.sixty,
    this.movementsToAvoid = const [],
  });

  Questionnaire copyWith({
    Goal? goal,
    Experience? experience,
    int? daysPerWeek,
    Set<EquipmentType>? availableEquipment,
    SessionDuration? sessionDuration,
    List<String>? movementsToAvoid,
  }) {
    return Questionnaire(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      movementsToAvoid: movementsToAvoid ?? this.movementsToAvoid,
    );
  }
}
