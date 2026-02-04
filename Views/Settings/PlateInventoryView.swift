import SwiftUI
import SwiftData

struct PlateInventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plate.weight, order: .reverse) private var plates: [Plate]
    @State private var showingAddSheet = false
    @State private var newWeight: Double = 10
    @State private var newCount: Int = 2
    @State private var newColor: String = "gray"
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lb
    }

    private let colorOptions = ["blue", "yellow", "green", "white", "red", "gray", "black"]

    var body: some View {
        List {
            ForEach(plates) { plate in
                HStack {
                    Circle()
                        .fill(plateColor(plate.color))
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading) {
                        Text("\(formatted(plate.weight)) \(plate.unit.abbreviation)")
                            .font(.headline)
                        Text("\(plate.count) plates (\(plate.count / 2) pairs)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Stepper("", value: Binding(
                        get: { plate.count },
                        set: { newValue in
                            plate.count = max(0, newValue)
                        }
                    ), in: 0...20, step: 2)
                    .labelsHidden()
                }
            }
            .onDelete(perform: deletePlates)
        }
        .navigationTitle("Plates")
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
                    Section("Plate Details") {
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("Weight", value: $newWeight, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }

                        Stepper("Count: \(newCount)", value: $newCount, in: 2...20, step: 2)

                        Picker("Color", selection: $newColor) {
                            ForEach(colorOptions, id: \.self) { color in
                                HStack {
                                    Circle()
                                        .fill(plateColor(color))
                                        .frame(width: 16, height: 16)
                                    Text(color.capitalized)
                                }
                                .tag(color)
                            }
                        }
                    }
                }
                .navigationTitle("Add Plate")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addPlate()
                        }
                    }
                }
            }
        }
    }

    private func addPlate() {
        let plate = Plate(weight: newWeight, unit: unit, count: newCount, color: newColor)
        modelContext.insert(plate)
        showingAddSheet = false
        newWeight = 10
        newCount = 2
        newColor = "gray"
    }

    private func deletePlates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plates[index])
        }
    }

    private func plateColor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        case "white": return .white
        case "red": return .red
        case "black": return .black
        case "gray": return .gray
        default: return .gray
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
