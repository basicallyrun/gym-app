import SwiftUI
import SwiftData
import Charts

struct WeeklyStatsView: View {
    @Query(sort: \WorkoutSession.startTime) private var allSessions: [WorkoutSession]

    private var weeklyData: [WeeklyDataPoint] {
        let calendar = Calendar.current
        let completedSessions = allSessions.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return [] }

        // Group sessions by week (last 8 weeks)
        var data: [WeeklyDataPoint] = []
        let now = Date.now

        for weeksAgo in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                continue
            }

            let sessionsThisWeek = completedSessions.filter {
                $0.startTime >= weekInterval.start && $0.startTime < weekInterval.end
            }

            let totalSets = sessionsThisWeek.reduce(0) {
                $0 + $1.setLogs.filter { $0.isCompleted && !$0.isWarmup }.count
            }

            let totalVolume = sessionsThisWeek.reduce(0.0) { total, session in
                total + session.setLogs
                    .filter { $0.isCompleted && !$0.isWarmup }
                    .reduce(0.0) { $0 + ($1.actualWeight * Double($1.actualReps)) }
            }

            let label = weekLabel(weekInterval.start)

            data.append(WeeklyDataPoint(
                week: label,
                workouts: sessionsThisWeek.count,
                sets: totalSets,
                volume: totalVolume
            ))
        }

        return data
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workouts per week chart
                chartSection(title: "Workouts per Week") {
                    Chart(weeklyData) { point in
                        BarMark(
                            x: .value("Week", point.week),
                            y: .value("Workouts", point.workouts)
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }

                // Volume per week chart
                chartSection(title: "Volume per Week") {
                    Chart(weeklyData) { point in
                        BarMark(
                            x: .value("Week", point.week),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(.green)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }

                // Sets per week chart
                chartSection(title: "Sets per Week") {
                    Chart(weeklyData) { point in
                        BarMark(
                            x: .value("Week", point.week),
                            y: .value("Sets", point.sets)
                        )
                        .foregroundStyle(.orange)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
            }
            .padding()
        }
        .navigationTitle("Weekly Stats")
    }

    @ViewBuilder
    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func weekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

struct WeeklyDataPoint: Identifiable {
    let id = UUID()
    let week: String
    let workouts: Int
    let sets: Int
    let volume: Double
}
