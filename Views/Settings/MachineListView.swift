import SwiftUI
import SwiftData

struct MachineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.name) private var machines: [Machine]
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newMinWeight: Double = 10
    @State private var newMaxWeight: Double = 200
    @State private var newIncrement: Double = 10
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lb
    }

    var body: some View {
        List {
            ForEach(machines) { machine in
                VStack(alignment: .leading) {
                    Text(machine.name)
                        .font(.headline)
                    Text("\(formatted(machine.minWeight))-\(formatted(machine.maxWeight)) \(machine.unit.abbreviation), \(formatted(machine.increment)) \(machine.unit.abbreviation) increments")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: deleteMachines)

            if machines.isEmpty {
                ContentUnavailableView(
                    "No Machines",
                    systemImage: "gearshape.2",
                    description: Text("Add machines from your gym")
                )
            }
        }
        .navigationTitle("Machines")
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
                    Section("Machine Details") {
                        TextField("Name", text: $newName)

                        HStack {
                            Text("Min Weight")
                            Spacer()
                            TextField("Min", value: $newMinWeight, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }

                        HStack {
                            Text("Max Weight")
                            Spacer()
                            TextField("Max", value: $newMaxWeight, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }

                        HStack {
                            Text("Increment")
                            Spacer()
                            TextField("Step", value: $newIncrement, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(unit.abbreviation)
                        }
                    }
                }
                .navigationTitle("Add Machine")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addMachine() }
                            .disabled(newName.isEmpty)
                    }
                }
            }
        }
    }

    private func addMachine() {
        let machine = Machine(
            name: newName,
            minWeight: newMinWeight,
            maxWeight: newMaxWeight,
            increment: newIncrement,
            unit: unit
        )
        modelContext.insert(machine)
        showingAddSheet = false
        resetForm()
    }

    private func deleteMachines(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(machines[index])
        }
    }

    private func resetForm() {
        newName = ""
        newMinWeight = 10
        newMaxWeight = 200
        newIncrement = 10
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
