import Foundation

// MARK: - Questionnaire Model

struct Questionnaire {
    enum Goal: String, Codable, CaseIterable, Identifiable {
        case strength, hypertrophy, generalFitness, powerlifting, athleticPerformance

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .hypertrophy: return "Hypertrophy"
            case .generalFitness: return "General Fitness"
            case .powerlifting: return "Powerlifting"
            case .athleticPerformance: return "Athletic Performance"
            }
        }
    }

    enum Experience: String, Codable, CaseIterable, Identifiable {
        case beginner, intermediate, advanced

        var id: String { rawValue }

        var displayName: String { rawValue.capitalized }
    }

    enum SessionDuration: Int, Codable, CaseIterable, Identifiable {
        case thirty = 30
        case fortyFive = 45
        case sixty = 60
        case seventyFive = 75
        case ninety = 90

        var id: Int { rawValue }

        var displayName: String { "\(rawValue) min" }
    }

    var goal: Goal = .strength
    var experience: Experience = .beginner
    var daysPerWeek: Int = 3
    var availableEquipment: Set<EquipmentType> = [.barbell, .dumbbell]
    var sessionDuration: SessionDuration = .sixty
    var movementsToAvoid: [String] = []
}

// MARK: - Program Template

struct ProgramTemplate: Codable, Identifiable {
    var id: String
    var name: String
    var description: String
    var goals: [String]
    var experienceLevels: [String]
    var daysPerWeek: Int
    var estimatedSessionMinutes: Int
    var requiredEquipment: [String]
    var days: [ProgramDay]

    struct ProgramDay: Codable, Identifiable {
        var id: String { name }
        var name: String
        var exercises: [ProgramExercise]
    }

    struct ProgramExercise: Codable {
        var exerciseName: String
        var sets: Int
        var repMin: Int
        var repMax: Int
        var restSeconds: Int
        var equipmentType: String
    }
}

// MARK: - Recommendation

struct ProgramRecommendation: Identifiable {
    var id: String { template.id }
    var template: ProgramTemplate
    var score: Double
    var rationale: [String]
}

// MARK: - Generator

struct ProgramGenerator {

    /// Load program templates from bundled JSON files.
    static func loadTemplates() -> [ProgramTemplate] {
        let templateNames = [
            "starting_strength",
            "ppl",
            "upper_lower",
            "full_body_3x",
            "five_three_one"
        ]

        var templates: [ProgramTemplate] = []
        for name in templateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Templates"),
               let data = try? Data(contentsOf: url),
               let template = try? JSONDecoder().decode(ProgramTemplate.self, from: data) {
                templates.append(template)
            }
        }
        return templates
    }

    /// Filter and score templates based on questionnaire answers.
    /// Returns ranked recommendations (top 3).
    static func recommend(for questionnaire: Questionnaire) -> [ProgramRecommendation] {
        let templates = loadTemplates()
        var recommendations: [ProgramRecommendation] = []

        for template in templates {
            var score: Double = 0
            var rationale: [String] = []

            // 1. Filter by experience level
            let experienceMatch = template.experienceLevels.contains(questionnaire.experience.rawValue)
            if !experienceMatch { continue }

            // 2. Filter by goal compatibility
            let goalMatch = template.goals.contains(questionnaire.goal.rawValue)
            if goalMatch {
                score += 30
                rationale.append("Matches your \(questionnaire.goal.displayName) goal")
            } else {
                continue
            }

            // 3. Days per week compatibility
            let daysDiff = abs(template.daysPerWeek - questionnaire.daysPerWeek)
            if daysDiff == 0 {
                score += 25
                rationale.append("Exactly \(questionnaire.daysPerWeek) days/week as requested")
            } else if daysDiff == 1 {
                score += 10
                rationale.append("Close match: \(template.daysPerWeek) days/week (you wanted \(questionnaire.daysPerWeek))")
            } else {
                continue // Too far off on days
            }

            // 4. Session duration compatibility
            let durationDiff = abs(template.estimatedSessionMinutes - questionnaire.sessionDuration.rawValue)
            if durationDiff <= 15 {
                score += 20
                rationale.append("Fits within your time budget")
            } else if durationDiff <= 30 {
                score += 5
                rationale.append("May slightly exceed your time budget")
            }

            // 5. Equipment availability scoring
            let requiredTypes = Set(template.requiredEquipment.compactMap { EquipmentType(rawValue: $0) })
            let availableTypes = questionnaire.availableEquipment
            let missingEquipment = requiredTypes.subtracting(availableTypes)

            if missingEquipment.isEmpty {
                score += 25
                rationale.append("All required equipment available")
            } else {
                let penalty = Double(missingEquipment.count) * 10.0
                score -= penalty
                let missingNames = missingEquipment.map { $0.displayName }.joined(separator: ", ")
                rationale.append("Missing equipment: \(missingNames)")
            }

            // 6. Penalize if movements to avoid overlap with template exercises
            if !questionnaire.movementsToAvoid.isEmpty {
                let allExercises = template.days.flatMap { $0.exercises.map { $0.exerciseName.lowercased() } }
                let avoided = questionnaire.movementsToAvoid.map { $0.lowercased() }
                let conflicts = allExercises.filter { exercise in
                    avoided.contains { exercise.contains($0) }
                }
                if !conflicts.isEmpty {
                    score -= Double(conflicts.count) * 5.0
                    rationale.append("Contains \(conflicts.count) exercise(s) you may want to substitute")
                }
            }

            recommendations.append(ProgramRecommendation(
                template: template,
                score: score,
                rationale: rationale
            ))
        }

        return recommendations
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }
}
