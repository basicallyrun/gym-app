import Foundation
import SwiftData

struct ProgressionResult {
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let passed: Bool
    let deloaded: Bool
    let message: String
}

struct ProgressionEngine {

    /// Evaluate workout results for a single exercise and apply progression rules.
    /// Returns the result describing what changed.
    static func evaluate(
        exercise: Exercise,
        setLogs: [SetLog],
        progressionRule: ProgressionRule,
        routineExercise: RoutineExercise
    ) -> ProgressionResult {
        let workingSets = setLogs.filter { !$0.isWarmup && $0.isCompleted }

        guard !workingSets.isEmpty else {
            return ProgressionResult(
                exerciseName: exercise.name,
                previousWeight: workingSets.first?.targetWeight ?? 0,
                newWeight: workingSets.first?.targetWeight ?? 0,
                passed: false,
                deloaded: false,
                message: "No working sets completed"
            )
        }

        let currentWeight = workingSets.first?.targetWeight ?? 0
        let passed: Bool

        switch progressionRule.triggerType {
        case .allSetsCompleted:
            // All prescribed sets must be completed at or above target reps
            let targetSets = routineExercise.targetSets
            let targetRepMin = routineExercise.targetRepMin
            let completedAtTarget = workingSets.filter { $0.actualReps >= targetRepMin }
            passed = completedAtTarget.count >= targetSets

        case .topSetHit:
            // Only the heaviest set needs to hit target reps
            let topSet = workingSets.max(by: { $0.actualWeight < $1.actualWeight })
            passed = (topSet?.actualReps ?? 0) >= routineExercise.targetRepMin
        }

        if passed {
            // Success: increase weight, reset failure count
            let newWeight = currentWeight + progressionRule.incrementAmount
            progressionRule.consecutiveFailures = 0
            return ProgressionResult(
                exerciseName: exercise.name,
                previousWeight: currentWeight,
                newWeight: newWeight,
                passed: true,
                deloaded: false,
                message: "Increase weight to \(formatted(newWeight)) \(progressionRule.unit.rawValue)"
            )
        } else {
            // Failure: check if deload is needed
            progressionRule.consecutiveFailures += 1

            if progressionRule.consecutiveFailures >= progressionRule.deloadAfterFailures {
                // Deload triggered
                let deloadAmount = currentWeight * progressionRule.deloadPercentage
                let newWeight = roundToNearest(currentWeight - deloadAmount, increment: progressionRule.incrementAmount)
                progressionRule.consecutiveFailures = 0
                return ProgressionResult(
                    exerciseName: exercise.name,
                    previousWeight: currentWeight,
                    newWeight: newWeight,
                    passed: false,
                    deloaded: true,
                    message: "Deload to \(formatted(newWeight)) \(progressionRule.unit.rawValue) after \(progressionRule.deloadAfterFailures) consecutive failures"
                )
            } else {
                // Keep same weight
                return ProgressionResult(
                    exerciseName: exercise.name,
                    previousWeight: currentWeight,
                    newWeight: currentWeight,
                    passed: false,
                    deloaded: false,
                    message: "Repeat \(formatted(currentWeight)) \(progressionRule.unit.rawValue) (failure \(progressionRule.consecutiveFailures)/\(progressionRule.deloadAfterFailures))"
                )
            }
        }
    }

    /// Round a weight down to the nearest increment
    private static func roundToNearest(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value }
        return (value / increment).rounded(.down) * increment
    }

    private static func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
