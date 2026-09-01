import Foundation
import SwiftData

@Model
final class FavoriteFood {
    var id: UUID = UUID()
    var name: String = ""
    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    
    init(id: UUID = UUID(), name: String, caloriesPer100g: Double, proteinPer100g: Double) {
        self.id = id
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
    }
}
