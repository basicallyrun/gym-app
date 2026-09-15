import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/questionnaire.dart';
import '../models/program_recommendation.dart';
import '../logic/program_generator.dart';

class ProgramGeneratorNotifier extends StateNotifier<Questionnaire> {
  ProgramGeneratorNotifier() : super(const Questionnaire());

  void updateQuestionnaire(Questionnaire questionnaire) {
    state = questionnaire;
  }

  Future<List<ProgramRecommendation>> getRecommendations() async {
    return await ProgramGenerator.recommend(state);
  }
}

final programGeneratorProvider = StateNotifierProvider<ProgramGeneratorNotifier, Questionnaire>((ref) {
  return ProgramGeneratorNotifier();
});
