import Foundation
import SwiftUI

enum MealCategory: String, Codable, CaseIterable, Identifiable {
    case desayuno = "Desayuno"
    case almuerzo = "Almuerzo"
    case comida = "Comida"
    case merienda = "Merienda"
    case cena = "Cena"
    case extra = "Extra"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .desayuno:
            return "sunrise.fill"
        case .almuerzo:
            return "sun.max.fill"
        case .comida:
            return "fork.knife"
        case .merienda:
            return "cup.and.saucer.fill"
        case .cena:
            return "moon.stars.fill"
        case .extra:
            return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .desayuno:
            return .orange
        case .almuerzo:
            return .yellow
        case .comida:
            return .red
        case .merienda:
            return .brown
        case .cena:
            return .indigo
        case .extra:
            return .purple
        }
    }
}
