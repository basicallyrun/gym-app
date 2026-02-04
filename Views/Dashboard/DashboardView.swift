import SwiftUI
import SwiftData

struct DashboardView: View {
    @Bindable var workoutViewModel: WorkoutViewModel
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    private var recentSessions: [WorkoutSession] {
        Array(sessions.filter { $0.isCompleted }.prefix(5))
    }

    private var thisWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return sessions.filter { $0.isCompleted && $0.startTime >= startOfWeek }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Start Card
                    if let nextRoutine = routines.first {
                        quickStartCard(nextRoutine)
                    }

                    // Weekly Stats
                    weeklyStatsCard

                    // Recent Sessions
                    if !recentSessions.isEmpty {
                        recentSessionsCard
                    }

                    // Empty state
                    if sessions.isEmpty && routines.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)

                            Text("Welcome to GymApp")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Set up your equipment and create a routine to get started.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 12) {
                                Button {
                                    selectedTab = 4
                                } label: {
                                    Label("Equipment", systemImage: "gearshape")
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    selectedTab = 1
                                } label: {
                                    Label("Routines", systemImage: "list.bullet")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    @ViewBuilder
    private func quickStartCard(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Workout")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(routine.routineExercises.count) exercises")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    workoutViewModel.startWorkout(routine: routine, modelContext: modelContext)
                    selectedTab = 2
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 24) {
                statItem(
                    value: "\(thisWeekSessions.count)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional"
                )

                statItem(
                    value: "\(totalSetsThisWeek)",
                    label: "Sets",
                    icon: "checkmark.circle"
                )

                statItem(
                    value: totalVolumeThisWeek,
                    label: "Volume",
                    icon: "scalemass"
                )
            }

            NavigationLink {
                WeeklyStatsView()
            } label: {
                Text("View Details")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                Spacer()
                Button {
                    selectedTab = 3
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }

            ForEach(recentSessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.routine?.name ?? "Workout")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(session.startTime, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var totalSetsThisWeek: Int {
        thisWeekSessions.reduce(0) { $0 + $1.setLogs.filter { $0.isCompleted }.count }
    }

    private var totalVolumeThisWeek: String {
        let volume = thisWeekSessions.reduce(0.0) { total, session in
            total + session.setLogs
                .filter { $0.isCompleted && !$0.isWarmup }
                .reduce(0.0) { $0 + ($1.actualWeight * Double($1.actualReps)) }
        }
        if volume >= 1000 {
            return String(format: "%.0fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}
