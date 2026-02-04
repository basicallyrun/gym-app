import Foundation
import SwiftData

@Model
final class Barbell {
    var name: String
    var weight: Double
    var unit: WeightUnit
    var isDefault: Bool

    init(name: String, weight: Double, unit: WeightUnit = .lb, isDefault: Bool = false) {
        self.name = name
        self.weight = weight
        self.unit = unit
        self.isDefault = isDefault
    }
}

@Model
final class DumbbellSet {
    var availableWeights: [Double]
    var unit: WeightUnit

    init(availableWeights: [Double], unit: WeightUnit = .lb) {
        self.availableWeights = availableWeights
        self.unit = unit
    }
}

@Model
final class Plate {
    var weight: Double
    var unit: WeightUnit
    var count: Int
    var color: String

    init(weight: Double, unit: WeightUnit = .lb, count: Int, color: String = "gray") {
        self.weight = weight
        self.unit = unit
        self.count = count
        self.color = color
    }
}

@Model
final class Machine {
    var name: String
    var minWeight: Double
    var maxWeight: Double
    var increment: Double
    var unit: WeightUnit

    init(name: String, minWeight: Double, maxWeight: Double, increment: Double, unit: WeightUnit = .lb) {
        self.name = name
        self.minWeight = minWeight
        self.maxWeight = maxWeight
        self.increment = increment
        self.unit = unit
    }
}

@Model
final class CableAttachment {
    var name: String

    init(name: String) {
        self.name = name
    }
}
