import SwiftUI
import SwiftData

struct ProgramGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var questionnaire = Questionnaire()
    @State private var currentStep = 0
    @State private var recommendations: [ProgramRecommendation] = []
    @State private var showingResults = false

    private let totalSteps = 5

    var body: some View {
        VStack {
            // Progress indicator
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps + 1))
                .padding(.horizontal)

            TabView(selection: $currentStep) {
                goalStep.tag(0)
                experienceStep.tag(1)
                daysStep.tag(2)
                equipmentStep.tag(3)
                durationStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Recommendations") {
                        generateRecommendations()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Program Generator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(isPresented: $showingResults) {
            NavigationStack {
                recommendationsView
            }
        }
    }

    // MARK: - Steps

    private var goalStep: some View {
        VStack(spacing: 24) {
            Text("What's your primary goal?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(Questionnaire.Goal.allCases) { goal in
                    Button {
                        questionnaire.goal = goal
                    } label: {
                        HStack {
                            Text(goal.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if questionnaire.goal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(questionnaire.goal == goal ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var experienceStep: some View {
        VStack(spacing: 24) {
            Text("What's your training experience?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(Questionnaire.Experience.allCases) { level in
                    Button {
                        questionnaire.experience = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                    .foregroundStyle(.primary)
                                Text(experienceDescription(level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if questionnaire.experience == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(questionnaire.experience == level ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var daysStep: some View {
        VStack(spacing: 24) {
            Text("How many days per week?")
                .font(.title2)
                .fontWeight(.semibold)

            Picker("Days", selection: $questionnaire.daysPerWeek) {
                ForEach(2...6, id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            .pickerStyle(.wheel)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var equipmentStep: some View {
        VStack(spacing: 24) {
            Text("What equipment do you have?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(EquipmentType.allCases) { equipment in
                    Button {
                        if questionnaire.availableEquipment.contains(equipment) {
                            questionnaire.availableEquipment.remove(equipment)
                        } else {
                            questionnaire.availableEquipment.insert(equipment)
                        }
                    } label: {
                        HStack {
                            Text(equipment.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if questionnaire.availableEquipment.contains(equipment) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            questionnaire.availableEquipment.contains(equipment)
                                ? Color.accentColor.opacity(0.1)
                                : Color(.systemGray6)
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var durationStep: some View {
        VStack(spacing: 24) {
            Text("How long is each session?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(Questionnaire.SessionDuration.allCases) { duration in
                    Button {
                        questionnaire.sessionDuration = duration
                    } label: {
                        HStack {
                            Text(duration.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if questionnaire.sessionDuration == duration {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(questionnaire.sessionDuration == duration ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    // MARK: - Results

    private var recommendationsView: some View {
        List {
            if recommendations.isEmpty {
                ContentUnavailableView(
                    "No Matches",
                    systemImage: "magnifyingglass",
                    description: Text("No programs match your criteria. Try adjusting your preferences.")
                )
            } else {
                ForEach(recommendations) { rec in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(rec.template.name)
                                    .font(.headline)
                                Spacer()
                                Text("Score: \(Int(rec.score))")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.fill)
                                    .cornerRadius(8)
                            }

                            Text(rec.template.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ForEach(rec.rationale, id: \.self) { reason in
                                Label(reason, systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 16) {
                                Label("\(rec.template.daysPerWeek) days/wk", systemImage: "calendar")
                                Label("~\(rec.template.estimatedSessionMinutes) min", systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                            Button("Use This Program") {
                                createRoutineFromTemplate(rec.template)
                                showingResults = false
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { showingResults = false }
            }
        }
    }

    // MARK: - Helpers

    private func generateRecommendations() {
        recommendations = ProgramGenerator.recommend(for: questionnaire)
        showingResults = true
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

    private func experienceDescription(_ level: Questionnaire.Experience) -> String {
        switch level {
        case .beginner: return "Less than 1 year of consistent training"
        case .intermediate: return "1-3 years of consistent training"
        case .advanced: return "3+ years of consistent training"
        }
    }
}
