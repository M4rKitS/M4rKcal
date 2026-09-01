import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID = UUID()
    var date: Date = Date()
    var waistCm: Double?
    var chestCm: Double?
    var thighCm: Double?
    var hipCm: Double?
    
    init(id: UUID = UUID(), date: Date = Date(), waistCm: Double? = nil, chestCm: Double? = nil, thighCm: Double? = nil, hipCm: Double? = nil) {
        self.id = id
        self.date = date
        self.waistCm = waistCm
        self.chestCm = chestCm
        self.thighCm = thighCm
        self.hipCm = hipCm
    }
}
