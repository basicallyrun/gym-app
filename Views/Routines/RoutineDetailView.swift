import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routine: Routine
    @State private var showingExercisePicker = false
    @State private var showingExportSheet = false
    @State private var exportDocument: RoutineDocument?

    private var sortedExercises: [RoutineExercise] {
        routine.routineExercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section {
                TextField("Routine Name", text: $routine.name)
                    .font(.headline)
            }

            Section("Exercises") {
                ForEach(sortedExercises) { routineExercise in
                    NavigationLink {
                        RoutineExerciseEditView(routineExercise: routineExercise)
                    } label: {
                        exerciseRow(routineExercise)
                    }
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            }

            if let source = routine.source {
                Section("Info") {
                    LabeledContent("Source", value: source)
                    LabeledContent("Template", value: routine.isTemplate ? "Yes" : "No")
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }

            ToolbarItem(placement: .secondaryAction) {
                Button {
                    exportRoutine()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                }
            }
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "\(routine.name).json"
        ) { _ in }
    }

    @ViewBuilder
    private func exerciseRow(_ re: RoutineExercise) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(re.exercise?.name ?? "Unknown Exercise")
                .font(.headline)

            HStack(spacing: 8) {
                Text("\(re.targetSets) sets")
                Text("x")
                Text("\(re.repRangeDisplay) reps")
                if let rpe = re.targetRPE {
                    Text("@ RPE \(String(format: "%.0f", rpe))")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let nextOrder = (sortedExercises.last?.order ?? -1) + 1
        let category = exercise.category
        let restSeconds = category == .compound ? 90 : 60

        let routineExercise = RoutineExercise(
            exercise: exercise,
            order: nextOrder,
            targetSets: 3,
            targetRepMin: category == .compound ? 5 : 8,
            targetRepMax: category == .compound ? 5 : 12,
            restSeconds: restSeconds
        )
        routine.routineExercises.append(routineExercise)
    }

    private func deleteExercises(at offsets: IndexSet) {
        let exercisesToDelete = offsets.map { sortedExercises[$0] }
        for exercise in exercisesToDelete {
            modelContext.delete(exercise)
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var exercises = sortedExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
    }

    private func exportRoutine() {
        if let document = try? ImportExportService.createDocument(from: routine) {
            exportDocument = document
            showingExportSheet = true
        }
    }
}
