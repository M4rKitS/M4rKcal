import SwiftUI

struct AppleWatchRingsView: View {
    var moveProgress: Double
    var exerciseProgress: Double
    var standProgress: Double
    var size: CGFloat = 72
    var ringThickness: CGFloat = 6
    var ringSpacing: CGFloat = 2.5
    
    var body: some View {
        ZStack {
            // Anillo exterior: Movimiento (Rojo)
            ringLayer(
                progress: moveProgress,
                color: Color.watchMoveRed,
                radius: size / 2 - ringThickness / 2
            )
            
            // Anillo medio: Ejercicio (Verde)
            ringLayer(
                progress: exerciseProgress,
                color: Color.watchExerciseGreen,
                radius: size / 2 - ringThickness * 1.5 - ringSpacing
            )
            
            // Anillo interior: De pie (Cian)
            ringLayer(
                progress: standProgress,
                color: Color.watchStandCyan,
                radius: size / 2 - ringThickness * 2.5 - ringSpacing * 2
            )
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    private func ringLayer(progress: Double, color: Color, radius: CGFloat) -> some View {
        let diameter = radius * 2
        ZStack {
            // Track de fondo con opacidad
            Circle()
                .stroke(color.opacity(0.2), lineWidth: ringThickness)
                .frame(width: diameter, height: diameter)
            
            // Progreso principal
            Circle()
                .trim(from: 0, to: min(CGFloat(progress), 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Si supera el 100% de la meta
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(CGFloat(progress) - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.8),
                        style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: diameter, height: diameter)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AppleWatchRingsView(
            moveProgress: 0.85,
            exerciseProgress: 0.60,
            standProgress: 0.90,
            size: 80,
            ringThickness: 7,
            ringSpacing: 3
        )
    }
}
