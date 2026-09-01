import SwiftUI
import SwiftData

@main
struct M4rkcalApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealEntry.self,
            DailyGoal.self,
            FavoriteFood.self,
            WeightEntry.self,
            BodyMeasurement.self
        ])
        
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// Vista Raíz que gestiona la Splash Screen y el TabView principal
struct RootContentView: View {
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack {
            // TabView principal (se inicializa y carga datos en segundo plano)
            MainTabView()
            
            // Pantalla de bienvenida animada superpuesta
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // Espera 2.8 segundos y desvanece suavemente la Splash Screen
            do {
                try await Task.sleep(nanoseconds: 2_800_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            } catch {
                showSplash = false
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showBarcodeScanner: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido de la pestaña activa
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    HistoryView()
                case 2:
                    NavigationStack {
                        EditMeasurementView(date: Calendar.current.startOfDay(for: Date()))
                    }
                case 3:
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Barra de Navegación Inferior Personalizada
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .tint(.appTerracotta)
        .sheet(isPresented: $showBarcodeScanner) {
            QuickScanSheet()
        }
    }
    
    // MARK: - Custom Bottom Navigation Bar
    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.appBorder.opacity(0.4))
            
            HStack(alignment: .bottom, spacing: 0) {
                // 1. Resumen
                tabButton(
                    title: "Resumen",
                    systemImage: "circle.circle.fill",
                    tabIndex: 0
                )
                
                // 2. Historial
                tabButton(
                    title: "Historial",
                    systemImage: "calendar",
                    tabIndex: 1
                )
                
                // 3. Botón Central Elevado "Escanear"
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showBarcodeScanner = true
                } label: {
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.appTerracotta)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.appTerracotta.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(y: -12)
                        
                        Text("Escanear")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .offset(y: -10)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                
                // 4. Medidas
                tabButton(
                    title: "Medidas",
                    systemImage: "scalemass.fill",
                    tabIndex: 2
                )
                
                // 5. Ajustes
                tabButton(
                    title: "Ajustes",
                    systemImage: "gearshape.fill",
                    tabIndex: 3
                )
            }
            .padding(.top, 6)
            .padding(.bottom, 22)
            .padding(.horizontal, 4)
            .background(Color.appSurface.ignoresSafeArea(edges: .bottom))
        }
    }
    
    private func tabButton(title: String, systemImage: String, tabIndex: Int) -> some View {
        let isSelected = selectedTab == tabIndex
        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            selectedTab = tabIndex
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appTerracotta : .appTextSecondary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .appTerracotta : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
