import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Exportable Routine Structure

struct ExportableRoutine: Codable {
    var name: String
    var source: String?
    var exercises: [ExportableExercise]

    struct ExportableExercise: Codable {
        var exerciseName: String
        var order: Int
        var targetSets: Int
        var targetRepMin: Int
        var targetRepMax: Int
        var targetRPE: Double?
        var restSeconds: Int
        var incrementAmount: Double?
        var incrementUnit: String?
    }
}

// MARK: - File Document for Share Sheet

struct RoutineDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Import/Export Service

struct ImportExportService {

    static func exportRoutine(_ routine: Routine) throws -> Data {
        let exportable = ExportableRoutine(
            name: routine.name,
            source: routine.source,
            exercises: routine.routineExercises
                .sorted { $0.order < $1.order }
                .map { re in
                    ExportableRoutine.ExportableExercise(
                        exerciseName: re.exercise?.name ?? "Unknown",
                        order: re.order,
                        targetSets: re.targetSets,
                        targetRepMin: re.targetRepMin,
                        targetRepMax: re.targetRepMax,
                        targetRPE: re.targetRPE,
                        restSeconds: re.restSeconds,
                        incrementAmount: re.progressionRule?.incrementAmount,
                        incrementUnit: re.progressionRule?.unit.rawValue
                    )
                }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportable)
    }

    static func importRoutine(from data: Data, exerciseLibrary: [Exercise]) throws -> (name: String, exercises: [(exerciseName: String, sets: Int, repMin: Int, repMax: Int, rpe: Double?, rest: Int)]) {
        let decoder = JSONDecoder()
        let importedRoutine = try decoder.decode(ExportableRoutine.self, from: data)

        let exercises = importedRoutine.exercises.sorted { $0.order < $1.order }.map { ex in
            (
                exerciseName: ex.exerciseName,
                sets: ex.targetSets,
                repMin: ex.targetRepMin,
                repMax: ex.targetRepMax,
                rpe: ex.targetRPE,
                rest: ex.restSeconds
            )
        }

        return (name: importedRoutine.name, exercises: exercises)
    }

    static func createDocument(from routine: Routine) throws -> RoutineDocument {
        let data = try exportRoutine(routine)
        return RoutineDocument(data: data)
    }
}
