import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressChartView: View {
    let exercise: Exercise

    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.startTime
    )
    private var sessions: [WorkoutSession]

    private var progressData: [ProgressDataPoint] {
        var points: [ProgressDataPoint] = []

        for session in sessions {
            let exerciseSets = session.setLogs.filter {
                $0.exercise?.persistentModelID == exercise.persistentModelID
                    && $0.isCompleted
                    && !$0.isWarmup
            }

            guard !exerciseSets.isEmpty else { continue }

            let maxWeight = exerciseSets.max(by: { $0.actualWeight < $1.actualWeight })?.actualWeight ?? 0
            let totalVolume = exerciseSets.reduce(0.0) { $0 + ($1.actualWeight * Double($1.actualReps)) }
            let maxReps = exerciseSets.max(by: { $0.actualReps < $1.actualReps })?.actualReps ?? 0

            points.append(ProgressDataPoint(
                date: session.startTime,
                maxWeight: maxWeight,
                totalVolume: totalVolume,
                maxReps: maxReps
            ))
        }

        return points
    }

    @State private var selectedMetric: Metric = .maxWeight

    enum Metric: String, CaseIterable {
        case maxWeight = "Max Weight"
        case volume = "Volume"
        case maxReps = "Max Reps"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(Metric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if progressData.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete workouts with this exercise to see progress")
                    )
                } else {
                    chartView
                        .frame(height: 250)
                        .padding()

                    // Stats summary
                    statsView
                }
            }
            .padding(.top)
        }
        .navigationTitle(exercise.name)
    }

    @ViewBuilder
    private var chartView: some View {
        switch selectedMetric {
        case .maxWeight:
            Chart(progressData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.maxWeight)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.maxWeight)
                )
                .foregroundStyle(.blue)
            }
            .chartYAxisLabel("Weight (lb)")

        case .volume:
            Chart(progressData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(.green)
                .symbol(.circle)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(.green)
            }
            .chartYAxisLabel("Volume (lb)")

        case .maxReps:
            Chart(progressData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Reps", point.maxReps)
                )
                .foregroundStyle(.orange)
                .symbol(.circle)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Reps", point.maxReps)
                )
                .foregroundStyle(.orange)
            }
            .chartYAxisLabel("Reps")
        }
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            if let first = progressData.first, let last = progressData.last, progressData.count > 1 {
                let weightChange = last.maxWeight - first.maxWeight
                let changePercent = first.maxWeight > 0 ? (weightChange / first.maxWeight) * 100 : 0

                LabeledContent("Starting Weight", value: "\(formatted(first.maxWeight)) lb")
                LabeledContent("Current Weight", value: "\(formatted(last.maxWeight)) lb")

                HStack {
                    Text("Change")
                    Spacer()
                    Text("\(weightChange >= 0 ? "+" : "")\(formatted(weightChange)) lb (\(String(format: "%.1f", changePercent))%)")
                        .foregroundStyle(weightChange >= 0 ? .green : .red)
                }

                LabeledContent("Sessions", value: "\(progressData.count)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let maxReps: Int
}
