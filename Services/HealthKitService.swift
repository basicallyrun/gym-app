import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        isAuthorized = true
    }

    func saveWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double? = nil,
        metadata: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            try await requestAuthorization()
        }

        var workoutMetadata: [String: Any] = metadata ?? [:]
        workoutMetadata[HKMetadataKeyWorkoutBrandName] = "GymApp"

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: totalEnergyBurned.map {
                HKQuantity(unit: .kilocalorie(), doubleValue: $0)
            },
            totalDistance: nil,
            metadata: workoutMetadata
        )

        try await healthStore.save(workout)
    }
}
