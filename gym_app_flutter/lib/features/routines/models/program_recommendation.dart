import 'program_template.dart';

class ProgramRecommendation {
  final ProgramTemplate template;
  final double score;
  final List<String> rationale;

  const ProgramRecommendation({
    required this.template,
    required this.score,
    required this.rationale,
  });
}
