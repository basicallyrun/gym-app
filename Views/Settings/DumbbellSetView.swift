import SwiftUI
import SwiftData

struct DumbbellSetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dumbbellSets: [DumbbellSet]
    @State private var showingAddSheet = false
    @State private var minWeight: Double = 5
    @State private var maxWeight: Double = 75
    @State private var increment: Double = 5
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lb
    }

    var body: some View {
        List {
            ForEach(dumbbellSets) { dbSet in
                VStack(alignment: .leading) {
                    let sortedWeights = dbSet.availableWeights.sorted()
                    if let first = sortedWeights.first, let last = sortedWeights.last {
                        Text("\(formatted(first)) - \(formatted(last)) \(dbSet.unit.abbreviation)")
                            .font(.headline)
                    }
                    Text("\(dbSet.availableWeights.count) weights available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    let display = sortedWeights.prefix(8).map { formatted($0) }.joined(separator: ", ")
                    let suffix = sortedWeights.count > 8 ? "..." : ""
                    Text(display + suffix)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .onDelete(perform: deleteSets)

            if dumbbellSets.isEmpty {
                ContentUnavailableView(
                    "No Dumbbell Sets",
                    systemImage: "dumbbell",
                    description: Text("Add your available dumbbell weights")
                )
            }
        }
        .navigationTitle("Dumbbells")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    Section("Generate Dumbbell Range") {
                        HStack {
                            Text("Min Weight")
                            Spacer()
                            TextField("Min", value: $minWeight, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }
                        HStack {
                            Text("Max Weight")
                            Spacer()
                            TextField("Max", value: $maxWeight, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }
                        HStack {
                            Text("Increment")
                            Spacer()
                            TextField("Step", value: $increment, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }
                    }

                    Section("Preview") {
                        let weights = generateWeights()
                        Text(weights.map { formatted($0) }.joined(separator: ", "))
                            .font(.caption)
                    }
                }
                .navigationTitle("Add Dumbbell Set")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addSet() }
                    }
                }
            }
        }
    }

    private func generateWeights() -> [Double] {
        guard increment > 0 && minWeight <= maxWeight else { return [] }
        var weights: [Double] = []
        var current = minWeight
        while current <= maxWeight {
            weights.append(current)
            current += increment
        }
        return weights
    }

    private func addSet() {
        let weights = generateWeights()
        guard !weights.isEmpty else { return }
        let dbSet = DumbbellSet(availableWeights: weights, unit: unit)
        modelContext.insert(dbSet)
        showingAddSheet = false
    }

    private func deleteSets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dumbbellSets[index])
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
