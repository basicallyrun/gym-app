import SwiftUI

struct SetRowView: View {
    @Bindable var setLog: SetLog
    var onComplete: (Int, Double) -> Void
    var onUncomplete: () -> Void

    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Set number / warmup badge
            VStack {
                if setLog.isWarmup {
                    Text("W")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else {
                    Text("\(setLog.setNumber)")
                        .font(.headline)
                }
            }
            .frame(width: 30)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 4) {
                    Button {
                        editingWeight = max(0, editingWeight - 5)
                        updateSetLog()
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)

                    TextField("Wt", value: $editingWeight, format: .number)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .onChange(of: editingWeight) { _, _ in updateSetLog() }

                    Button {
                        editingWeight += 5
                        updateSetLog()
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
            }

            Spacer()

            // Reps
            VStack(alignment: .center, spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 4) {
                    Button {
                        editingReps = max(0, editingReps - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)

                    Text("\(editingReps)")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .frame(width: 30)
                        .multilineTextAlignment(.center)

                    Button {
                        editingReps += 1
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
            }

            // Completion toggle
            Button {
                if setLog.isCompleted {
                    onUncomplete()
                } else {
                    onComplete(editingReps, editingWeight)
                }
            } label: {
                Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(setLog.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(setLog.isCompleted ? 0.7 : 1.0)
        .onAppear {
            editingWeight = setLog.targetWeight
            editingReps = setLog.targetReps
        }
        .swipeActions(edge: .leading) {
            Button {
                setLog.isWarmup.toggle()
            } label: {
                Label(
                    setLog.isWarmup ? "Working" : "Warmup",
                    systemImage: setLog.isWarmup ? "flame.fill" : "flame"
                )
            }
            .tint(.orange)
        }
    }

    private func updateSetLog() {
        setLog.targetWeight = editingWeight
        if !setLog.isCompleted {
            setLog.actualWeight = editingWeight
        }
    }
}
