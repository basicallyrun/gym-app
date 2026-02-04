import SwiftUI
import SwiftData

struct InlinePlateCalculatorView: View {
    var targetWeight: Double

    @Query(filter: #Predicate<Barbell> { $0.isDefault == true }) private var defaultBarbells: [Barbell]
    @Query(sort: \Plate.weight, order: .reverse) private var plates: [Plate]

    private var loadout: PlateLoadout {
        let barWeight = defaultBarbells.first?.weight ?? 45
        return PlateCalculator.calculate(
            targetWeight: targetWeight,
            barWeight: barWeight,
            availablePlates: plates
        )
    }

    var body: some View {
        if targetWeight > 0 {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Per side:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if loadout.platesPerSide.isEmpty {
                        Text("Bar only")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        // Compact plate display
                        HStack(spacing: 2) {
                            ForEach(Array(loadout.platesPerSide.enumerated()), id: \.offset) { _, plate in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(plateColor(plate.color))
                                    .frame(width: 10, height: plateHeight(plate.weight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(.primary.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                        }

                        Spacer()

                        // Text summary
                        let grouped = Dictionary(grouping: loadout.platesPerSide, by: { $0.weight })
                        let summary = grouped.keys.sorted(by: >).map { weight in
                            let count = grouped[weight]?.count ?? 0
                            return "\(count)x\(formatted(weight))"
                        }.joined(separator: " + ")

                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !loadout.isExact && loadout.difference > 0 {
                    Text("Closest: \(formatted(loadout.totalWeight)) lb (\(formatted(loadout.difference)) under)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        switch weight {
        case 45...: return 32
        case 35..<45: return 28
        case 25..<35: return 24
        case 10..<25: return 20
        case 5..<10: return 16
        default: return 12
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
        default: return .gray
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
