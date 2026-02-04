import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var showingAddRoutine = false
    @State private var showingTemplates = false
    @State private var showingGenerator = false
    @State private var newRoutineName = ""

    private var userRoutines: [Routine] {
        routines.filter { !$0.isTemplate }
    }

    private var templateRoutines: [Routine] {
        routines.filter { $0.isTemplate }
    }

    var body: some View {
        NavigationStack {
            List {
                if !userRoutines.isEmpty {
                    Section("My Routines") {
                        ForEach(userRoutines) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine)
                            } label: {
                                routineRow(routine)
                            }
                        }
                        .onDelete { offsets in
                            deleteRoutines(offsets, from: userRoutines)
                        }
                    }
                }

                if !templateRoutines.isEmpty {
                    Section("Templates") {
                        ForEach(templateRoutines) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine)
                            } label: {
                                routineRow(routine)
                            }
                        }
                    }
                }

                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Create a routine, browse templates, or use the program generator")
                    )
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddRoutine = true
                        } label: {
                            Label("New Routine", systemImage: "plus")
                        }

                        Button {
                            showingTemplates = true
                        } label: {
                            Label("Browse Templates", systemImage: "doc.text")
                        }

                        Button {
                            showingGenerator = true
                        } label: {
                            Label("Program Generator", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Routine", isPresented: $showingAddRoutine) {
                TextField("Routine Name", text: $newRoutineName)
                Button("Cancel", role: .cancel) { newRoutineName = "" }
                Button("Create") {
                    createRoutine()
                }
            }
            .sheet(isPresented: $showingTemplates) {
                NavigationStack {
                    TemplateBrowserView()
                }
            }
            .sheet(isPresented: $showingGenerator) {
                NavigationStack {
                    ProgramGeneratorView()
                }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .font(.headline)

            let exerciseCount = routine.routineExercises.count
            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let source = routine.source {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func createRoutine() {
        guard !newRoutineName.isEmpty else { return }
        let routine = Routine(name: newRoutineName, source: "Custom")
        modelContext.insert(routine)
        newRoutineName = ""
    }

    private func deleteRoutines(_ offsets: IndexSet, from list: [Routine]) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}
