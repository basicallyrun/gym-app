import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var showingExerciseList = false
    @State private var showingCancelAlert = false

    var body: some View {
        NavigationStack {
            if viewModel.isWorkoutActive {
                activeWorkoutView
            } else {
                startWorkoutView
            }
        }
    }

    // MARK: - Start View

    private var startWorkoutView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Active Workout")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a workout from your routines")
                .foregroundStyle(.secondary)

            if !routines.isEmpty {
                VStack(spacing: 12) {
                    ForEach(routines.prefix(5)) { routine in
                        Button {
                            viewModel.startWorkout(routine: routine, modelContext: modelContext)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(routine.name)
                                        .font(.headline)
                                    Text("\(routine.routineExercises.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .tint(.primary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Workout")
    }

    // MARK: - Active Workout

    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Exercise Header
            if let routineExercise = viewModel.currentRoutineExercise {
                exerciseHeader(routineExercise)
            }

            // Set List
            List {
                ForEach(viewModel.currentSetLogs) { setLog in
                    SetRowView(
                        setLog: setLog,
                        onComplete: { reps, weight in
                            viewModel.completeSet(setLog, actualReps: reps, actualWeight: weight)
                        },
                        onUncomplete: {
                            viewModel.uncompleteSet(setLog)
                        }
                    )
                }

                // Inline plate calculator
                if let re = viewModel.currentRoutineExercise,
                   re.exercise?.equipmentType == .barbell {
                    Section("Plate Calculator") {
                        InlinePlateCalculatorView(
                            targetWeight: viewModel.currentSetLogs.first?.targetWeight ?? 0
                        )
                    }
                }
            }

            // Bottom bar
            bottomBar
        }
        .navigationTitle(viewModel.session?.routine?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExerciseList = true
                } label: {
                    Image(systemName: "list.bullet")
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .destructive) {
                    showingCancelAlert = true
                }
            }
        }
        .overlay {
            if viewModel.isRestTimerRunning {
                RestTimerView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingExerciseList) {
            WorkoutExerciseListView(viewModel: viewModel)
        }
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                viewModel.cancelWorkout()
            }
        } message: {
            Text("This will discard all progress from this workout.")
        }
    }

    @ViewBuilder
    private func exerciseHeader(_ routineExercise: RoutineExercise) -> some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    viewModel.previousExercise()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(viewModel.currentExerciseIndex == 0)

                Spacer()

                VStack {
                    Text(routineExercise.exercise?.name ?? "Exercise")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(routineExercise.targetSets) x \(routineExercise.repRangeDisplay)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.nextExercise()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(viewModel.currentExerciseIndex >= viewModel.totalExercises - 1)
            }

            Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.totalExercises)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(viewModel.completedSetsCount)/\(viewModel.totalSetsCount) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(viewModel.completedSetsCount), total: Double(max(1, viewModel.totalSetsCount)))
                    .tint(.green)
            }

            Spacer()

            Button {
                viewModel.finishWorkout()
            } label: {
                Text("Finish Workout")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
