import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession

    private var exerciseGroups: [(exercise: Exercise, sets: [SetLog])] {
        let completedSets = session.setLogs.sorted { $0.setNumber < $1.setNumber }
        var groups: [(exercise: Exercise, sets: [SetLog])] = []
        var seen: Set<PersistentIdentifier> = []

        for setLog in completedSets {
            guard let exercise = setLog.exercise else { continue }
            if !seen.contains(exercise.persistentModelID) {
                seen.insert(exercise.persistentModelID)
                let exerciseSets = completedSets.filter {
                    $0.exercise?.persistentModelID == exercise.persistentModelID
                }
                groups.append((exercise: exercise, sets: exerciseSets))
            }
        }

        return groups
    }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Routine", value: session.routine?.name ?? "Unknown")
                LabeledContent("Date") {
                    Text(session.startTime, style: .date)
                }
                LabeledContent("Duration", value: session.durationFormatted)

                let completedSets = session.setLogs.filter { $0.isCompleted && !$0.isWarmup }
                LabeledContent("Working Sets", value: "\(completedSets.count)")

                let totalVolume = completedSets.reduce(0.0) { $0 + ($1.actualWeight * Double($1.actualReps)) }
                LabeledContent("Total Volume", value: "\(formatted(totalVolume)) lb")
            }

            ForEach(exerciseGroups, id: \.exercise.persistentModelID) { group in
                Section(group.exercise.name) {
                    ForEach(group.sets) { setLog in
                        HStack {
                            if setLog.isWarmup {
                                Text("W")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                            } else {
                                Text("\(setLog.setNumber)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24)
                            }

                            Text("\(formatted(setLog.actualWeight)) \(setLog.unit.abbreviation)")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(setLog.actualReps) reps")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let rpe = setLog.rpe {
                                Text("RPE \(String(format: "%.0f", rpe))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(setLog.isCompleted ? .green : .red)
                        }
                        .font(.subheadline)
                    }

                    // Exercise summary
                    let workingSets = group.sets.filter { !$0.isWarmup && $0.isCompleted }
                    if !workingSets.isEmpty {
                        let maxWeight = workingSets.max(by: { $0.actualWeight < $1.actualWeight })?.actualWeight ?? 0
                        let totalReps = workingSets.reduce(0) { $0 + $1.actualReps }
                        HStack {
                            Text("Best: \(formatted(maxWeight)) \(workingSets.first?.unit.abbreviation ?? "lb")")
                            Spacer()
                            Text("Total: \(totalReps) reps")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }
        }
        .navigationTitle("Session Details")
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
