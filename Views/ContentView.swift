import SwiftUI

struct ContentView: View {
    @State private var workoutViewModel = WorkoutViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(workoutViewModel: workoutViewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            WorkoutView(viewModel: workoutViewModel)
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .badge(workoutViewModel.isWorkoutActive ? "!" : nil)
                .tag(2)

            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .environment(workoutViewModel)
    }
}
