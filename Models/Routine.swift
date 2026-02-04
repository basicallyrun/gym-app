import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    @Relationship(deleteRule: .cascade)
    var routineExercises: [RoutineExercise]
    var isTemplate: Bool
    var source: String?
    var createdAt: Date

    init(
        name: String,
        routineExercises: [RoutineExercise] = [],
        isTemplate: Bool = false,
        source: String? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.routineExercises = routineExercises
        self.isTemplate = isTemplate
        self.source = source
        self.createdAt = createdAt
    }
}

@Model
final class RoutineExercise {
    var exercise: Exercise?
    var order: Int
    var targetSets: Int
    var targetRepMin: Int
    var targetRepMax: Int
    var targetRPE: Double?
    var restSeconds: Int
    var progressionRule: ProgressionRule?
    @Relationship(inverse: \Routine.routineExercises)
    var routine: Routine?

    init(
        exercise: Exercise? = nil,
        order: Int = 0,
        targetSets: Int = 3,
        targetRepMin: Int = 5,
        targetRepMax: Int = 5,
        targetRPE: Double? = nil,
        restSeconds: Int = 90,
        progressionRule: ProgressionRule? = nil
    ) {
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
        self.targetRPE = targetRPE
        self.restSeconds = restSeconds
        self.progressionRule = progressionRule
    }

    var repRangeDisplay: String {
        if targetRepMin == targetRepMax {
            return "\(targetRepMin)"
        }
        return "\(targetRepMin)-\(targetRepMax)"
    }
}
