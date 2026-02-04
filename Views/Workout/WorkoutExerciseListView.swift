import SwiftUI

struct WorkoutExerciseListView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WorkoutViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.currentRoutineExercises.enumerated()), id: \.element.id) { index, routineExercise in
                    Button {
                        viewModel.goToExercise(at: index)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routineExercise.exercise?.name ?? "Exercise")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("\(routineExercise.targetSets) x \(routineExercise.repRangeDisplay)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Show completion status
                            let exerciseSets = setsForExercise(routineExercise)
                            let completed = exerciseSets.filter { $0.isCompleted }.count
                            let total = exerciseSets.count

                            if total > 0 {
                                Text("\(completed)/\(total)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(completed == total ? Color.green.opacity(0.2) : Color(.systemGray5))
                                    .cornerRadius(8)
                            }

                            if index == viewModel.currentExerciseIndex {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func setsForExercise(_ routineExercise: RoutineExercise) -> [SetLog] {
        guard let session = viewModel.session,
              let exercise = routineExercise.exercise else { return [] }
        return session.setLogs.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }
}
