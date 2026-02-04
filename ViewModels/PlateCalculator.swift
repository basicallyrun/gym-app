import Foundation

struct PlateLoadout {
    let platesPerSide: [(weight: Double, color: String)]
    let totalWeight: Double
    let isExact: Bool
    let difference: Double // 0 if exact, positive if under target
}

struct PlateCalculator {

    /// Greedy largest-first plate calculation.
    /// Returns exact plate list per side, or closest approximate with difference.
    static func calculate(
        targetWeight: Double,
        barWeight: Double,
        availablePlates: [Plate]
    ) -> PlateLoadout {
        let remainingTotal = targetWeight - barWeight
        guard remainingTotal >= 0 else {
            return PlateLoadout(
                platesPerSide: [],
                totalWeight: barWeight,
                isExact: false,
                difference: abs(remainingTotal)
            )
        }

        var remainingPerSide = remainingTotal / 2.0
        var platesPerSide: [(weight: Double, color: String)] = []

        // Build a sorted list of plate denominations (largest first)
        // Each entry tracks how many are available (count / 2 = pairs available)
        var inventory: [(weight: Double, color: String, pairsAvailable: Int)] = availablePlates
            .filter { $0.count >= 2 }
            .map { (weight: $0.weight, color: $0.color, pairsAvailable: $0.count / 2) }
            .sorted { $0.weight > $1.weight }

        for i in inventory.indices {
            while remainingPerSide >= inventory[i].weight && inventory[i].pairsAvailable > 0 {
                platesPerSide.append((weight: inventory[i].weight, color: inventory[i].color))
                remainingPerSide -= inventory[i].weight
                inventory[i].pairsAvailable -= 1
            }
        }

        let achievedPerSide = platesPerSide.reduce(0.0) { $0 + $1.weight }
        let achievedTotal = barWeight + (achievedPerSide * 2.0)
        let isExact = abs(remainingPerSide) < 0.001
        let difference = remainingPerSide * 2.0

        return PlateLoadout(
            platesPerSide: platesPerSide,
            totalWeight: achievedTotal,
            isExact: isExact,
            difference: difference
        )
    }
}
