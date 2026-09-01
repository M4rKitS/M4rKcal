import SwiftUI

struct ActivityRingView: View {
    var progress: Double
    var color: Color
    var thickness: CGFloat = 12
    var showBackground: Bool = true
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: thickness)
            }
            
            Circle()
                .trim(from: 0, to: min(CGFloat(progress), 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            // Si el progreso es mayor a 1, dibujamos un anillo extra encima
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(CGFloat(progress) - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.5), // Un tono ligeramente diferente o con opacidad para resaltar el extra
                        style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ActivityRingView(progress: 0.3, color: .green, thickness: 20)
            .frame(width: 100, height: 100)
        
        ActivityRingView(progress: 0.8, color: .orange, thickness: 15)
            .frame(width: 150, height: 150)
            
        ActivityRingView(progress: 1.2, color: .red, thickness: 20)
            .frame(width: 100, height: 100)
    }
    .padding()
}
