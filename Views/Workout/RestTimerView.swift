import SwiftUI

struct RestTimerView: View {
    @Bindable var viewModel: WorkoutViewModel

    private var progress: Double {
        guard let re = viewModel.currentRoutineExercise else { return 0 }
        let total = Double(re.restSeconds)
        guard total > 0 else { return 0 }
        return Double(viewModel.restTimeRemaining) / total
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap
                }

            VStack(spacing: 24) {
                Text("Rest Timer")
                    .font(.headline)
                    .foregroundStyle(.white)

                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.restTimeRemaining)

                    // Time display
                    VStack {
                        Text(timeFormatted(viewModel.restTimeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("remaining")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Controls
                HStack(spacing: 32) {
                    Button {
                        viewModel.extendRestTimer(by: -15)
                    } label: {
                        VStack {
                            Image(systemName: "minus.circle")
                                .font(.title)
                            Text("-15s")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                    }
                    .disabled(viewModel.restTimeRemaining <= 15)

                    Button {
                        viewModel.stopRestTimer()
                    } label: {
                        VStack {
                            Image(systemName: "forward.fill")
                                .font(.title)
                            Text("Skip")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                    }

                    Button {
                        viewModel.extendRestTimer(by: 30)
                    } label: {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.title)
                            Text("+30s")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(32)
        }
    }

    private func timeFormatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
