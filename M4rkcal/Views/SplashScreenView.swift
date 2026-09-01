import SwiftUI

struct SplashScreenView: View {
    @State private var isIconVisible: Bool = false
    @State private var isTextVisible: Bool = false
    @State private var isSloganVisible: Bool = false
    
    var body: some View {
        ZStack {
            // Fondo negro #050505 a pantalla completa
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Icono de la App (90x90pt, esquinas redondeadas ~22pt)
                appIconElement
                    .scaleEffect(isIconVisible ? 1.0 : 0.85)
                    .opacity(isIconVisible ? 1.0 : 0.0)
                
                VStack(spacing: 6) {
                    // Texto "M4rkcal" en SF Pro Display, 22pt, semibold, #F5F5F7
                    Text("M4rkcal")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(isTextVisible ? 1.0 : 0.0)
                        .offset(y: isTextVisible ? 0 : 4)
                    
                    // Eslogan "Más fuerte que el vinagre 💪🏽" en 14pt, terracota #C2703D
                    Text("Más fuerte que el vinagre 💪🏽")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTerracotta)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(isSloganVisible ? 1.0 : 0.0)
                        .offset(y: isSloganVisible ? 0 : 8)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            // Entrada del icono: spring tras 0.1s
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isIconVisible = true
            }
            
            // Entrada del título M4rkcal
            withAnimation(.easeOut(duration: 0.35).delay(0.25)) {
                isTextVisible = true
            }
            
            // Entrada del eslogan: fade-in + slide upward tras 0.4s
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                isSloganVisible = true
            }
        }
    }
    
    @ViewBuilder
    private var appIconElement: some View {
        Group {
            if UIImage(named: "AppLogo") != nil {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.appTerracotta.opacity(0.35), radius: 14, x: 0, y: 6)
            } else {
                // Representación vectorial con anillo terracota y llama
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.appSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                        )
                    
                    ZStack {
                        Circle()
                            .stroke(Color.appTerracotta.opacity(0.2), lineWidth: 5)
                            .frame(width: 56, height: 56)
                        
                        Circle()
                            .trim(from: 0.1, to: 0.9)
                            .stroke(
                                Color.appTerracotta,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 90, height: 90)
                .shadow(color: Color.appTerracotta.opacity(0.35), radius: 14, x: 0, y: 6)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
