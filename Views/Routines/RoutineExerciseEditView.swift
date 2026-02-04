import SwiftUI
import SwiftData

struct RoutineExerciseEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routineExercise: RoutineExercise
    @State private var showProgressionConfig = false

    var body: some View {
        Form {
            Section("Exercise") {
                if let exercise = routineExercise.exercise {
                    LabeledContent("Name", value: exercise.name)
                    LabeledContent("Category", value: exercise.category.displayName)
                    LabeledContent("Equipment", value: exercise.equipmentType.displayName)
                    if !exercise.muscleGroups.isEmpty {
                        LabeledContent("Muscles") {
                            Text(exercise.muscleGroups.map { $0.displayName }.joined(separator: ", "))
                        }
                    }
                }
            }

            Section("Sets & Reps") {
                Stepper("Sets: \(routineExercise.targetSets)", value: $routineExercise.targetSets, in: 1...10)

                Stepper("Min Reps: \(routineExercise.targetRepMin)", value: $routineExercise.targetRepMin, in: 1...30)

                Stepper("Max Reps: \(routineExercise.targetRepMax)", value: $routineExercise.targetRepMax, in: routineExercise.targetRepMin...30)

                HStack {
                    Text("Target RPE")
                    Spacer()
                    if let rpe = routineExercise.targetRPE {
                        Text(String(format: "%.0f", rpe))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("None")
                            .foregroundStyle(.tertiary)
                    }
                    Stepper("", value: Binding(
                        get: { routineExercise.targetRPE ?? 7 },
                        set: { routineExercise.targetRPE = $0 }
                    ), in: 5...10, step: 0.5)
                    .labelsHidden()
                }
            }

            Section("Rest Timer") {
                Stepper("Rest: \(routineExercise.restSeconds)s", value: $routineExercise.restSeconds, in: 15...300, step: 15)

                HStack {
                    ForEach([60, 90, 120, 180], id: \.self) { seconds in
                        Button("\(seconds)s") {
                            routineExercise.restSeconds = seconds
                        }
                        .buttonStyle(.bordered)
                        .tint(routineExercise.restSeconds == seconds ? .blue : .gray)
                    }
                }
            }

            Section("Progression") {
                if let rule = routineExercise.progressionRule {
                    progressionRuleView(rule)
                } else {
                    Button("Add Progression Rule") {
                        addProgressionRule()
                    }
                }
            }

            Section("Preview") {
                Text("\(routineExercise.targetSets) x \(routineExercise.repRangeDisplay)")
                    .font(.title2)
                    .fontWeight(.semibold)
                if let rpe = routineExercise.targetRPE {
                    Text("@ RPE \(String(format: "%.0f", rpe))")
                        .foregroundStyle(.secondary)
                }
                Text("Rest: \(routineExercise.restSeconds)s between sets")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationTitle(routineExercise.exercise?.name ?? "Edit Exercise")
    }

    @ViewBuilder
    private func progressionRuleView(_ rule: ProgressionRule) -> some View {
        HStack {
            Text("Increment")
            Spacer()
            TextField("Amount", value: Binding(
                get: { rule.incrementAmount },
                set: { rule.incrementAmount = $0 }
            ), format: .number)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .frame(width: 60)
            Text(rule.unit.abbreviation)
        }

        Picker("Trigger", selection: Binding(
            get: { rule.triggerType },
            set: { rule.triggerType = $0 }
        )) {
            ForEach(ProgressionTrigger.allCases) { trigger in
                Text(trigger.displayName).tag(trigger)
            }
        }

        Stepper("Deload after \(rule.deloadAfterFailures) failures", value: Binding(
            get: { rule.deloadAfterFailures },
            set: { rule.deloadAfterFailures = $0 }
        ), in: 1...10)

        HStack {
            Text("Deload")
            Spacer()
            Text("\(Int(rule.deloadPercentage * 100))%")
            Stepper("", value: Binding(
                get: { rule.deloadPercentage },
                set: { rule.deloadPercentage = $0 }
            ), in: 0.05...0.30, step: 0.05)
            .labelsHidden()
        }

        Button("Remove Progression Rule", role: .destructive) {
            modelContext.delete(rule)
            routineExercise.progressionRule = nil
        }
    }

    private func addProgressionRule() {
        let isCompound = routineExercise.exercise?.category == .compound
        let rule = ProgressionRule(
            exercise: routineExercise.exercise,
            incrementAmount: isCompound ? 5.0 : 2.5,
            unit: .lb,
            triggerType: .allSetsCompleted,
            deloadPercentage: 0.10,
            deloadAfterFailures: 3
        )
        modelContext.insert(rule)
        routineExercise.progressionRule = rule
    }
}
