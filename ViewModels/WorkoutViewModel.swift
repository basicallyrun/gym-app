import Foundation
import SwiftData
import Combine

@Observable
final class WorkoutViewModel {
    var session: WorkoutSession?
    var currentExerciseIndex: Int = 0
    var isRestTimerRunning: Bool = false
    var restTimeRemaining: Int = 0
    var isWorkoutActive: Bool = false

    private var timerCancellable: AnyCancellable?
    private var modelContext: ModelContext?

    var currentRoutineExercises: [RoutineExercise] {
        guard let routine = session?.routine else { return [] }
        return routine.routineExercises.sorted { $0.order < $1.order }
    }

    var currentRoutineExercise: RoutineExercise? {
        let exercises = currentRoutineExercises
        guard currentExerciseIndex >= 0 && currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var currentSetLogs: [SetLog] {
        guard let session,
              let exercise = currentRoutineExercise?.exercise else { return [] }
        return session.setLogs
            .filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
            .sorted { $0.setNumber < $1.setNumber }
    }

    var totalExercises: Int {
        currentRoutineExercises.count
    }

    var completedSetsCount: Int {
        session?.setLogs.filter { $0.isCompleted }.count ?? 0
    }

    var totalSetsCount: Int {
        currentRoutineExercises.reduce(0) { $0 + $1.targetSets }
    }

    // MARK: - Workout Lifecycle

    func startWorkout(routine: Routine, modelContext: ModelContext) {
        self.modelContext = modelContext
        let newSession = WorkoutSession(routine: routine)
        modelContext.insert(newSession)

        // Create initial set logs for all exercises
        for routineExercise in routine.routineExercises.sorted(by: { $0.order < $1.order }) {
            guard let exercise = routineExercise.exercise else { continue }
            for setNumber in 1...routineExercise.targetSets {
                let setLog = SetLog(
                    exercise: exercise,
                    setNumber: setNumber,
                    targetWeight: 0, // User will set weight
                    targetReps: routineExercise.targetRepMin,
                    unit: .lb
                )
                newSession.setLogs.append(setLog)
            }
        }

        self.session = newSession
        self.currentExerciseIndex = 0
        self.isWorkoutActive = true
    }

    func finishWorkout() {
        session?.endTime = .now
        session?.isCompleted = true
        isWorkoutActive = false
        stopRestTimer()
    }

    func cancelWorkout() {
        if let session {
            modelContext?.delete(session)
        }
        session = nil
        isWorkoutActive = false
        stopRestTimer()
    }

    // MARK: - Set Completion

    func completeSet(_ setLog: SetLog, actualReps: Int, actualWeight: Double) {
        setLog.actualReps = actualReps
        setLog.actualWeight = actualWeight
        setLog.isCompleted = true
        setLog.timestamp = .now

        // Auto-start rest timer
        if let restSeconds = currentRoutineExercise?.restSeconds, restSeconds > 0 {
            startRestTimer(seconds: restSeconds)
        }
    }

    func uncompleteSet(_ setLog: SetLog) {
        setLog.isCompleted = false
        setLog.actualReps = 0
    }

    // MARK: - Navigation

    func nextExercise() {
        if currentExerciseIndex < totalExercises - 1 {
            currentExerciseIndex += 1
            stopRestTimer()
        }
    }

    func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            stopRestTimer()
        }
    }

    func goToExercise(at index: Int) {
        guard index >= 0 && index < totalExercises else { return }
        currentExerciseIndex = index
        stopRestTimer()
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        isRestTimerRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.stopRestTimer()
                }
            }
    }

    func stopRestTimer() {
        isRestTimerRunning = false
        restTimeRemaining = 0
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func extendRestTimer(by seconds: Int = 30) {
        restTimeRemaining += seconds
    }

    // MARK: - Weight Adjustments

    func incrementWeight(for setLog: SetLog, by amount: Double = 5.0) {
        setLog.targetWeight += amount
        setLog.actualWeight = setLog.targetWeight
    }

    func decrementWeight(for setLog: SetLog, by amount: Double = 5.0) {
        setLog.targetWeight = max(0, setLog.targetWeight - amount)
        setLog.actualWeight = setLog.targetWeight
    }

    func setWeightForAllSets(_ weight: Double) {
        for setLog in currentSetLogs where !setLog.isWarmup {
            setLog.targetWeight = weight
            if !setLog.isCompleted {
                setLog.actualWeight = weight
            }
        }
    }
}
