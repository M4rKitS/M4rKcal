import Foundation
import SwiftData

@Model
final class WeightEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var weightKg: Double = 0.0
    
    init(id: UUID = UUID(), date: Date = Date(), weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
    }
}
