import SwiftUI

// MARK: - Color Palette
extension Color {
    // MARK: Primary Brand & Accents
    /// Terracota (#C2703D) - Acento principal para calorías, pestaña activa, botones principales, día seleccionado
    static let appTerracotta = Color(hex: "C2703D")
    
    /// Cian (#06B6D4) - Acento secundario para proteínas
    static let appCyan = Color(hex: "06B6D4")
    
    // MARK: States
    /// Verde (#22C55E) - Éxito / Déficit calórico favorable
    static let appSuccess = Color(hex: "22C55E")
    
    /// Ámbar (#F59E0B) - Aviso / Advertencia
    static let appWarning = Color(hex: "F59E0B")
    
    /// Rojo (#EF4444) - Error / Exceso calórico sobre el objetivo
    static let appError = Color(hex: "EF4444")
    
    // MARK: Dark Surfaces & Backgrounds
    /// Fondo negro profundo (#050505)
    static let appBackground = Color(hex: "050505")
    
    /// Superficie de tarjetas y agrupaciones (#121212)
    static let appSurface = Color(hex: "121212")
    
    /// Superficie elevada y elementos flotantes (#1C1C1E)
    static let appSurfaceElevated = Color(hex: "1C1C1E")
    
    /// Borde sutil para tarjetas (#2C2C2E)
    static let appBorder = Color(hex: "2C2C2E")
    
    // MARK: Typography
    /// Texto principal (#F5F5F7)
    static let appTextPrimary = Color(hex: "F5F5F7")
    
    /// Texto secundario (#8E8E93)
    static let appTextSecondary = Color(hex: "8E8E93")
    
    // MARK: Apple Watch Activity Ring Colors
    static let watchMoveRed = Color(hex: "FA114F")
    static let watchExerciseGreen = Color(hex: "AEEB34")
    static let watchStandCyan = Color(hex: "00D5DF")
    
    // MARK: Hex Initializer
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers for Cards
struct AppCardModifier: ViewModifier {
    var backgroundColor: Color = .appSurface
    var cornerRadius: CGFloat = 16
    var borderColor: Color = .appBorder.opacity(0.4)
    var borderWidth: CGFloat = 1
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

extension View {
    func appCard(
        backgroundColor: Color = .appSurface,
        cornerRadius: CGFloat = 16,
        borderColor: Color = .appBorder.opacity(0.4),
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(AppCardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth
        ))
    }
}
