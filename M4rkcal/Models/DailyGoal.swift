import Foundation
import SwiftData

@Model
final class DailyGoal {
    var id: UUID = UUID()
    var caloriesGoal: Int = 2000
    var caloriesGoalMin: Int = 2700
    var caloriesGoalMax: Int = 3000
    var proteinGoal: Double = 150.0
    
    init(id: UUID = UUID(), caloriesGoal: Int = 2000, caloriesGoalMin: Int = 2700, caloriesGoalMax: Int = 3000, proteinGoal: Double = 150.0) {
        self.id = id
        self.caloriesGoal = caloriesGoal
        self.caloriesGoalMin = caloriesGoalMin
        self.caloriesGoalMax = caloriesGoalMax
        self.proteinGoal = proteinGoal
    }
}
