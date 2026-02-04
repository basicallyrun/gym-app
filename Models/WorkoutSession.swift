import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var routine: Routine?
    var startTime: Date
    var endTime: Date?
    @Relationship(deleteRule: .cascade)
    var setLogs: [SetLog]
    var notes: String
    var isCompleted: Bool

    init(
        routine: Routine? = nil,
        startTime: Date = .now,
        endTime: Date? = nil,
        setLogs: [SetLog] = [],
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.routine = routine
        self.startTime = startTime
        self.endTime = endTime
        self.setLogs = setLogs
        self.notes = notes
        self.isCompleted = isCompleted
    }

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        guard let duration else { return "In Progress" }
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(remainingMinutes)m"
    }
}

@Model
final class SetLog {
    var exercise: Exercise?
    var setNumber: Int
    var targetWeight: Double
    var actualWeight: Double
    var targetReps: Int
    var actualReps: Int
    var unit: WeightUnit
    var isWarmup: Bool
    var timestamp: Date
    var rpe: Double?
    var isCompleted: Bool
    @Relationship(inverse: \WorkoutSession.setLogs)
    var session: WorkoutSession?

    init(
        exercise: Exercise? = nil,
        setNumber: Int = 1,
        targetWeight: Double = 0,
        actualWeight: Double = 0,
        targetReps: Int = 5,
        actualReps: Int = 0,
        unit: WeightUnit = .lb,
        isWarmup: Bool = false,
        timestamp: Date = .now,
        rpe: Double? = nil,
        isCompleted: Bool = false
    ) {
        self.exercise = exercise
        self.setNumber = setNumber
        self.targetWeight = targetWeight
        self.actualWeight = actualWeight
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.unit = unit
        self.isWarmup = isWarmup
        self.timestamp = timestamp
        self.rpe = rpe
        self.isCompleted = isCompleted
    }
}
