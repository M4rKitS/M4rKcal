import Foundation
import SwiftData

@Model
final class MealEntry {
    var id: UUID = UUID()
    var name: String = ""
    var calories: Int = 0
    var proteins: Double = 0.0
    var date: Date = Date()
    
    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var gramsConsumed: Double = 100.0
    
    var category: MealCategory = MealCategory.desayuno
    
    init(id: UUID = UUID(), name: String, calories: Int, proteins: Double, caloriesPer100g: Double = 0.0, proteinPer100g: Double = 0.0, gramsConsumed: Double = 100.0, date: Date = Date(), category: MealCategory) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteins = proteins
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.gramsConsumed = gramsConsumed
        self.date = date
        self.category = category
    }
}
