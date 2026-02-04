import Foundation
import SwiftData

@Model
final class ProgressionRule {
    var exercise: Exercise?
    var incrementAmount: Double
    var unit: WeightUnit
    var triggerType: ProgressionTrigger
    var consecutiveFailures: Int
    var deloadPercentage: Double
    var deloadAfterFailures: Int

    init(
        exercise: Exercise? = nil,
        incrementAmount: Double = 5.0,
        unit: WeightUnit = .lb,
        triggerType: ProgressionTrigger = .allSetsCompleted,
        consecutiveFailures: Int = 0,
        deloadPercentage: Double = 0.10,
        deloadAfterFailures: Int = 3
    ) {
        self.exercise = exercise
        self.incrementAmount = incrementAmount
        self.unit = unit
        self.triggerType = triggerType
        self.consecutiveFailures = consecutiveFailures
        self.deloadPercentage = deloadPercentage
        self.deloadAfterFailures = deloadAfterFailures
    }
}
