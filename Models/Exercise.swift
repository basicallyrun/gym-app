import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var equipmentType: EquipmentType
    var notes: String
    var isCustom: Bool

    init(
        name: String,
        category: ExerciseCategory,
        muscleGroups: [MuscleGroup],
        equipmentType: EquipmentType,
        notes: String = "",
        isCustom: Bool = false
    ) {
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipmentType = equipmentType
        self.notes = notes
        self.isCustom = isCustom
    }
}
