import SwiftUI
import SwiftData

struct PlateCalculatorView: View {
    @Query(sort: \Barbell.name) private var barbells: [Barbell]
    @Query(sort: \Plate.weight, order: .reverse) private var plates: [Plate]
    @State private var targetWeight: Double = 135
    @State private var selectedBarbellIndex: Int = 0
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lb
    }

    private var selectedBarbell: Barbell? {
        guard !barbells.isEmpty && selectedBarbellIndex < barbells.count else { return nil }
        return barbells[selectedBarbellIndex]
    }

    private var loadout: PlateLoadout {
        guard let barbell = selectedBarbell else {
            return PlateLoadout(platesPerSide: [], totalWeight: 0, isExact: false, difference: targetWeight)
        }
        return PlateCalculator.calculate(
            targetWeight: targetWeight,
            barWeight: barbell.weight,
            availablePlates: plates
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weight Input
                VStack(spacing: 12) {
                    Text("Target Weight")
                        .font(.headline)

                    HStack(spacing: 16) {
                        Button {
                            targetWeight = max(0, targetWeight - 5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                        }

                        TextField("Weight", value: $targetWeight, format: .number)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .frame(width: 150)

                        Button {
                            targetWeight += 5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }

                    Text(unit.abbreviation)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Barbell Picker
                if !barbells.isEmpty {
                    Picker("Barbell", selection: $selectedBarbellIndex) {
                        ForEach(barbells.indices, id: \.self) { index in
                            Text("\(barbells[index].name) (\(formatted(barbells[index].weight)) \(barbells[index].unit.abbreviation))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // Result
                if loadout.isExact {
                    Text("Exact Match")
                        .font(.headline)
                        .foregroundStyle(.green)
                } else if loadout.difference > 0 {
                    VStack(spacing: 4) {
                        Text("Closest: \(formatted(loadout.totalWeight)) \(unit.abbreviation)")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text("(\(formatted(loadout.difference)) \(unit.abbreviation) under target)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Plate Visual
                if !loadout.platesPerSide.isEmpty {
                    VStack(spacing: 8) {
                        Text("Per Side")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 2) {
                            // Bar end
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.gray.opacity(0.5))
                                .frame(width: 60, height: 20)

                            // Plates (largest to smallest, left to right)
                            ForEach(Array(loadout.platesPerSide.enumerated()), id: \.offset) { _, plate in
                                plateView(weight: plate.weight, color: plate.color)
                            }
                        }

                        // Plate summary
                        let grouped = Dictionary(grouping: loadout.platesPerSide, by: { $0.weight })
                        let sortedKeys = grouped.keys.sorted(by: >)
                        HStack(spacing: 12) {
                            ForEach(sortedKeys, id: \.self) { weight in
                                if let count = grouped[weight]?.count {
                                    Text("\(count)x \(formatted(weight))")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.fill)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
        }
        .navigationTitle("Plate Calculator")
        .onAppear {
            if let defaultIndex = barbells.firstIndex(where: { $0.isDefault }) {
                selectedBarbellIndex = defaultIndex
            }
        }
    }

    @ViewBuilder
    private func plateView(weight: Double, color: String) -> some View {
        let height: CGFloat = plateHeight(for: weight)
        RoundedRectangle(cornerRadius: 3)
            .fill(plateSwiftUIColor(color))
            .frame(width: 16, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.primary.opacity(0.3), lineWidth: 1)
            )
    }

    private func plateHeight(for weight: Double) -> CGFloat {
        switch weight {
        case 45...: return 100
        case 35..<45: return 90
        case 25..<35: return 80
        case 10..<25: return 65
        case 5..<10: return 50
        default: return 40
        }
    }

    private func plateSwiftUIColor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        case "white": return .white
        case "red": return .red
        case "black": return .black
        default: return .gray
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
