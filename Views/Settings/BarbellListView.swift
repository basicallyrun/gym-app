import SwiftUI
import SwiftData

struct BarbellListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Barbell.weight) private var barbells: [Barbell]
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newWeight: Double = 45
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lb
    }

    var body: some View {
        List {
            ForEach(barbells) { barbell in
                HStack {
                    VStack(alignment: .leading) {
                        Text(barbell.name)
                            .font(.headline)
                        Text("\(formatted(barbell.weight)) \(barbell.unit.abbreviation)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if barbell.isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setDefault(barbell)
                }
            }
            .onDelete(perform: deleteBarbells)
        }
        .navigationTitle("Barbells")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Barbell", isPresented: $showingAddSheet) {
            TextField("Name", text: $newName)
            TextField("Weight", value: $newWeight, format: .number)
            Button("Cancel", role: .cancel) {
                resetForm()
            }
            Button("Add") {
                addBarbell()
            }
        } message: {
            Text("Enter barbell details")
        }
    }

    private func addBarbell() {
        let barbell = Barbell(
            name: newName.isEmpty ? "Barbell" : newName,
            weight: newWeight,
            unit: unit,
            isDefault: barbells.isEmpty
        )
        modelContext.insert(barbell)
        resetForm()
    }

    private func setDefault(_ barbell: Barbell) {
        for b in barbells {
            b.isDefault = false
        }
        barbell.isDefault = true
    }

    private func deleteBarbells(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(barbells[index])
        }
    }

    private func resetForm() {
        newName = ""
        newWeight = 45
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
