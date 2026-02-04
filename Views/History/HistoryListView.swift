import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
        sort: \WorkoutSession.startTime,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workout History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Completed workouts will appear here")
                    )
                } else {
                    ForEach(groupedByMonth, id: \.key) { month, monthSessions in
                        Section(month) {
                            ForEach(monthSessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    sessionRow(session)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.routine?.name ?? "Workout")
                    .font(.headline)
                Spacer()
                Text(session.durationFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text(session.startTime, style: .date)
                Text(session.startTime, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            let completedSets = session.setLogs.filter { $0.isCompleted }
            Text("\(completedSets.count) sets completed")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var groupedByMonth: [(key: String, value: [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sessions) { session in
            formatter.string(from: session.startTime)
        }

        return grouped.sorted { a, b in
            guard let dateA = sessions.first(where: { formatter.string(from: $0.startTime) == a.key })?.startTime,
                  let dateB = sessions.first(where: { formatter.string(from: $0.startTime) == b.key })?.startTime else {
                return a.key > b.key
            }
            return dateA > dateB
        }
    }
}
