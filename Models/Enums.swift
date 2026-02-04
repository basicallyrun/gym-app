import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lb, kg

    var id: String { rawValue }

    var abbreviation: String { rawValue }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        if self == target { return value }
        switch (self, target) {
        case (.lb, .kg): return value * 0.453592
        case (.kg, .lb): return value / 0.453592
        default: return value
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case compound, isolation, cardio

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps
    case quads, hamstrings, glutes, calves, abs, forearms

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case barbell, dumbbell, machine, cable, bodyweight, other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum ProgressionTrigger: String, Codable, CaseIterable, Identifiable {
    case allSetsCompleted, topSetHit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allSetsCompleted: return "All Sets Completed"
        case .topSetHit: return "Top Set Hit"
        }
    }
}
