import SwiftUI
import SwiftData

struct TemplateBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var templates: [ProgramTemplate] = []
    @State private var selectedTemplate: ProgramTemplate?

    var body: some View {
        List {
            ForEach(templates) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(template.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)

                        HStack(spacing: 12) {
                            Label("\(template.daysPerWeek) days/wk", systemImage: "calendar")
                            Label("~\(template.estimatedSessionMinutes) min", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                        HStack(spacing: 4) {
                            ForEach(template.experienceLevels, id: \.self) { level in
                                Text(level.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.fill)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Program Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            templates = ProgramGenerator.loadTemplates()
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationStack {
                templateDetailView(template)
            }
        }
    }

    @ViewBuilder
    private func templateDetailView(_ template: ProgramTemplate) -> some View {
        List {
            Section {
                Text(template.description)
                    .font(.body)

                HStack(spacing: 16) {
                    Label("\(template.daysPerWeek) days/wk", systemImage: "calendar")
                    Label("~\(template.estimatedSessionMinutes) min", systemImage: "clock")
                }
                .font(.subheadline)
            }

            ForEach(template.days) { day in
                Section(day.name) {
                    ForEach(day.exercises, id: \.exerciseName) { exercise in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.exerciseName)
                                .font(.headline)

                            let repDisplay = exercise.repMin == exercise.repMax
                                ? "\(exercise.repMin)"
                                : "\(exercise.repMin)-\(exercise.repMax)"
                            Text("\(exercise.sets) x \(repDisplay) | Rest: \(exercise.restSeconds)s")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Use Template") {
                    createRoutineFromTemplate(template)
                    selectedTemplate = nil
                    dismiss()
                }
            }
        }
    }

    private func createRoutineFromTemplate(_ template: ProgramTemplate) {
        for day in template.days {
            let routine = Routine(
                name: "\(template.name) - \(day.name)",
                isTemplate: true,
                source: template.name
            )
            modelContext.insert(routine)

            for (index, templateExercise) in day.exercises.enumerated() {
                let matchedExercise = exercises.first { $0.name == templateExercise.exerciseName }

                let routineExercise = RoutineExercise(
                    exercise: matchedExercise,
                    order: index,
                    targetSets: templateExercise.sets,
                    targetRepMin: templateExercise.repMin,
                    targetRepMax: templateExercise.repMax,
                    restSeconds: templateExercise.restSeconds
                )
                routine.routineExercises.append(routineExercise)
            }
        }
    }
}
