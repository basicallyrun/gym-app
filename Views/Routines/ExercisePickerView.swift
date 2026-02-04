import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: EquipmentType?

    var onSelect: (Exercise) -> Void

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory

            let matchesMuscle = selectedMuscle == nil ||
                exercise.muscleGroups.contains(selectedMuscle!)

            let matchesEquipment = selectedEquipment == nil ||
                exercise.equipmentType == selectedEquipment

            return matchesSearch && matchesCategory && matchesMuscle && matchesEquipment
        }
    }

    var body: some View {
        List {
            Section {
                filtersView
            }

            ForEach(filteredExercises) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            Text(exercise.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill)
                                .cornerRadius(4)

                            Text(exercise.equipmentType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(exercise.muscleGroups.map { $0.displayName }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            if filteredExercises.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("Choose Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All") { selectedCategory = nil }
                    ForEach(ExerciseCategory.allCases) { cat in
                        Button(cat.displayName) { selectedCategory = cat }
                    }
                } label: {
                    filterChip(
                        title: selectedCategory?.displayName ?? "Category",
                        isActive: selectedCategory != nil
                    )
                }

                Menu {
                    Button("All") { selectedMuscle = nil }
                    ForEach(MuscleGroup.allCases) { muscle in
                        Button(muscle.displayName) { selectedMuscle = muscle }
                    }
                } label: {
                    filterChip(
                        title: selectedMuscle?.displayName ?? "Muscle",
                        isActive: selectedMuscle != nil
                    )
                }

                Menu {
                    Button("All") { selectedEquipment = nil }
                    ForEach(EquipmentType.allCases) { equip in
                        Button(equip.displayName) { selectedEquipment = equip }
                    }
                } label: {
                    filterChip(
                        title: selectedEquipment?.displayName ?? "Equipment",
                        isActive: selectedEquipment != nil
                    )
                }

                if selectedCategory != nil || selectedMuscle != nil || selectedEquipment != nil {
                    Button("Clear") {
                        selectedCategory = nil
                        selectedMuscle = nil
                        selectedEquipment = nil
                    }
                    .font(.caption)
                }
            }
        }
    }

    @ViewBuilder
    private func filterChip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
            .foregroundStyle(isActive ? .primary : .secondary)
            .cornerRadius(16)
    }
}
