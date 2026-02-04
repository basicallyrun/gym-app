import SwiftUI
import SwiftData

@main
struct GymApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Barbell.self,
                DumbbellSet.self,
                Plate.self,
                Machine.self,
                CableAttachment.self,
                Exercise.self,
                ProgressionRule.self,
                Routine.self,
                RoutineExercise.self,
                WorkoutSession.self,
                SetLog.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedDataIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }

    private func seedDataIfNeeded() {
        let context = modelContainer.mainContext
        let exerciseCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0

        if exerciseCount == 0 {
            seedExerciseLibrary(context: context)
            seedDefaultEquipment(context: context)
        }
    }

    private func seedExerciseLibrary(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "ExerciseLibrary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        struct ExerciseJSON: Decodable {
            let name: String
            let category: String
            let muscleGroups: [String]
            let equipmentType: String
            let notes: String
        }

        guard let exercises = try? JSONDecoder().decode([ExerciseJSON].self, from: data) else {
            return
        }

        for entry in exercises {
            let exercise = Exercise(
                name: entry.name,
                category: ExerciseCategory(rawValue: entry.category) ?? .compound,
                muscleGroups: entry.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                equipmentType: EquipmentType(rawValue: entry.equipmentType) ?? .barbell,
                notes: entry.notes,
                isCustom: false
            )
            context.insert(exercise)
        }

        try? context.save()
    }

    private func seedDefaultEquipment(context: ModelContext) {
        // Default Olympic barbell
        let olympicBar = Barbell(name: "Olympic Barbell", weight: 45, unit: .lb, isDefault: true)
        context.insert(olympicBar)

        // Default plates (standard Olympic set)
        let plateConfigs: [(weight: Double, count: Int, color: String)] = [
            (45, 4, "blue"),
            (35, 2, "yellow"),
            (25, 2, "green"),
            (10, 4, "white"),
            (5, 4, "red"),
            (2.5, 4, "gray")
        ]

        for config in plateConfigs {
            let plate = Plate(weight: config.weight, unit: .lb, count: config.count, color: config.color)
            context.insert(plate)
        }

        try? context.save()
    }
}
