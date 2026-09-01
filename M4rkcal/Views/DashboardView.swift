import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var viewModel = DashboardViewModel()
    @State private var wasViewingToday: Bool = true
    @State private var showAllCategories: Bool = true
    @State private var weekDeficits: [Date: Int] = [:]
    @State private var isLoadingWeekDeficits: Bool = false
    
    // Consultamos los objetivos diarios
    @Query private var goals: [DailyGoal]
    
    // Consultamos todas las entradas para filtrado local reactivo
    @Query(sort: \MealEntry.date, order: .reverse) private var allEntries: [MealEntry]
    
    @State private var categoryForSheet: MealCategory? = nil
    @State private var todayWorkout: TodayWorkoutSummary? = nil
    @State private var navigateToHistory: Bool = false
    
    private var dailyGoal: DailyGoal {
        goals.first ?? DailyGoal()
    }
    
    private var todaysEntries: [MealEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: viewModel.currentDate) }
    }
    
    private var totalCaloriesConsumed: Int {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProteinsConsumed: Double {
        todaysEntries.reduce(0) { $0 + $1.proteins }
    }
    
    private var remainingCalories: Int {
        max(0, dailyGoal.caloriesGoalMax - totalCaloriesConsumed)
    }
    
    private var remainingProteins: Double {
        max(0, dailyGoal.proteinGoal - totalProteinsConsumed)
    }
    
    private var netCalories: Int {
        totalCaloriesConsumed - viewModel.totalCaloriesBurned
    }
    
    // Categorías visibles según el filtro "Ver todas"
    private var visibleCategories: [MealCategory] {
        if showAllCategories {
            return MealCategory.allCases
        }
        let active = MealCategory.allCases.filter { cat in
            todaysEntries.contains(where: { $0.category == cat })
        }
        return active.isEmpty ? MealCategory.allCases : active
    }
    
    // Resumen de déficit de la semana actual
    private var currentWeekDays: [Date] {
        viewModel.currentWeekDays()
    }
    
    private var weeklyTotalDeficit: Int {
        let values = currentWeekDays.compactMap { weekDeficits[Calendar.current.startOfDay(for: $0)] }
        return values.reduce(0, +)
    }
    
    private var weeklyAverageDeficit: Int {
        let values = currentWeekDays.compactMap { weekDeficits[Calendar.current.startOfDay(for: $0)] }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / values.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Cabecera y Selector de Fecha
                    headerSection
                    
                    // 2. Anillos Principales (Calorías y Proteínas)
                    mainRingsSection
                    
                    // 3. Fila "Déficit hoy" + "Pasos"
                    quickStatsRow
                    
                    // 4. Sección Comidas
                    mealsSection
                    
                    // 5. Nueva Sección "Déficit calórico" (Resumen semanal navegable)
                    weeklyDeficitCard
                    
                    // 6. Nueva Sección "Actividad" (Apple Watch + Hevy)
                    activitySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 110) // Espacio holgado para no tapar la última tarjeta con el TabBar
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.appTerracotta)
                        Text("M4rkcal")
                            .font(.headline.bold())
                            .foregroundColor(.appTextPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !Calendar.current.isDateInToday(viewModel.currentDate) {
                        Button("Hoy") {
                            viewModel.goToToday()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.appTerracotta)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToHistory) {
                HistoryView()
            }
            .sheet(item: $categoryForSheet) { category in
                AddMealSheet(category: category, date: viewModel.currentDate)
            }
            .task {
                if goals.isEmpty {
                    let newGoal = DailyGoal(caloriesGoal: 2000, caloriesGoalMin: 2700, caloriesGoalMax: 3000, proteinGoal: 150.0)
                    modelContext.insert(newGoal)
                }
                await viewModel.loadHealthData()
                todayWorkout = await HevyService.shared.fetchTodayWorkout()
                await loadWeeklyDeficits()
            }
            .onChange(of: viewModel.currentDate) { _, _ in
                Task {
                    await loadWeeklyDeficits()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    wasViewingToday = Calendar.current.isDateInToday(viewModel.currentDate)
                } else if newPhase == .active {
                    if wasViewingToday && !Calendar.current.isDateInToday(viewModel.currentDate) {
                        viewModel.goToToday()
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Header & Week Selector
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedHeaderTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    
                    Text(viewModel.currentDate.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: viewModel.previousDay) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .padding(8)
                            .background(Color.appSurfaceElevated)
                            .clipShape(Circle())
                    }
                    
                    Button(action: viewModel.nextDay) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Calendar.current.isDateInToday(viewModel.currentDate) ? .appTextSecondary.opacity(0.3) : .appTextSecondary)
                            .padding(8)
                            .background(Color.appSurfaceElevated)
                            .clipShape(Circle())
                    }
                    .disabled(Calendar.current.isDateInToday(viewModel.currentDate))
                }
            }
            
            // Selector semanal de 7 días (L M X J V S D)
            WeekDaySelectorView(selectedDate: $viewModel.currentDate) { newDate in
                viewModel.selectDate(newDate)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
        }
    }
    
    private var formattedHeaderTitle: String {
        if Calendar.current.isDateInToday(viewModel.currentDate) {
            let dayMonth = viewModel.currentDate.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))).replacingOccurrences(of: ".", with: "")
            return "Hoy, \(dayMonth)"
        } else {
            return viewModel.currentDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(Locale(identifier: "es_ES"))).capitalized
        }
    }
    
    // MARK: - 2. Main Rings (Calorías & Proteínas)
    private var mainRingsSection: some View {
        HStack(spacing: 14) {
            // Anillo de Calorías
            VStack(spacing: 12) {
                // Icono pequeño SF Symbol arriba del anillo
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(totalCaloriesConsumed > dailyGoal.caloriesGoalMax ? .appError : .appTerracotta)
                    Text("CALORÍAS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
                
                ZStack {
                    ActivityRingView(
                        progress: Double(totalCaloriesConsumed) / Double(max(1, dailyGoal.caloriesGoalMax)),
                        color: totalCaloriesConsumed > dailyGoal.caloriesGoalMax ? .appError : .appTerracotta,
                        thickness: 12
                    )
                    .frame(width: 126, height: 126)
                    
                    VStack(spacing: 2) {
                        Text(formatKcal(totalCaloriesConsumed))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(totalCaloriesConsumed > dailyGoal.caloriesGoalMax ? .appError : .appTextPrimary)
                        
                        Text("/ \(formatKcal(dailyGoal.caloriesGoalMax))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                        
                        Text("kcal")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                // Píldora inferior de estado
                HStack(spacing: 4) {
                    if totalCaloriesConsumed > dailyGoal.caloriesGoalMax {
                        Text("+\(formatKcal(totalCaloriesConsumed - dailyGoal.caloriesGoalMax)) exceso")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appError)
                    } else {
                        Text("\(formatKcal(remainingCalories)) restantes")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.appTerracotta)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.appSurfaceElevated)
                .clipShape(Capsule())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
            
            // Anillo de Proteínas
            VStack(spacing: 12) {
                // Icono SF Symbol representativo de nutrición/comida (fork.knife)
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.appCyan)
                    Text("PROTEÍNAS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
                
                ZStack {
                    ActivityRingView(
                        progress: totalProteinsConsumed / max(1.0, dailyGoal.proteinGoal),
                        color: .appCyan,
                        thickness: 12
                    )
                    .frame(width: 126, height: 126)
                    
                    VStack(spacing: 2) {
                        Text("\(totalProteinsConsumed, specifier: "%.0f")")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        
                        Text("/ \(dailyGoal.proteinGoal, specifier: "%.0f")g")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                        
                        Text("consumidos")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                // Píldora inferior explícita con "Faltan: Xg"
                HStack(spacing: 4) {
                    if totalProteinsConsumed >= dailyGoal.proteinGoal {
                        Text("Objetivo cumplido")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appSuccess)
                    } else {
                        Text("Faltan: \(formatDouble(remainingProteins))g")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appCyan)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.appSurfaceElevated)
                .clipShape(Capsule())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 3. Quick Stats Row (Déficit hoy + Pasos)
    private var quickStatsRow: some View {
        HStack(spacing: 14) {
            // Tarjeta Déficit Hoy
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "flame.circle.fill")
                        .foregroundColor(netCalories < 0 ? .appSuccess : .appError)
                        .font(.system(size: 16))
                    Text("Déficit hoy")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(netCalories < 0 ? "\(formatKcal(netCalories))" : "+\(formatKcal(netCalories))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(netCalories < 0 ? .appSuccess : .appError)
                    Text("kcal")
                        .font(.caption.bold())
                        .foregroundColor(.appTextSecondary)
                }
                
                Text("Quemadas: \(formatKcal(viewModel.totalCaloriesBurned)) kcal")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
            
            // Tarjeta Pasos
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.appTerracotta)
                        .font(.system(size: 16))
                    Text("Pasos")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(formatKcal(viewModel.stepCount))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    Text("pasos")
                        .font(.caption.bold())
                        .foregroundColor(.appTextSecondary)
                }
                
                Text(viewModel.stepCount >= 10000 ? "Objetivo 10k superado" : "Objetivo: 10.000")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.stepCount >= 10000 ? .appSuccess : .appTextSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 4. Meals Section
    private var mealsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Comidas")
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAllCategories.toggle()
                    }
                } label: {
                    Text(showAllCategories ? "Solo registradas" : "Ver todas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appTerracotta)
                }
            }
            .padding(.horizontal, 2)
            
            VStack(spacing: 10) {
                ForEach(visibleCategories, id: \.self) { category in
                    CategorySectionView(
                        category: category,
                        entries: todaysEntries.filter { $0.category == category },
                        date: viewModel.currentDate,
                        onAdd: {
                            categoryForSheet = category
                        },
                        onDelete: { indexSet in
                            let categoryEntries = todaysEntries.filter { $0.category == category }
                            for index in indexSet {
                                modelContext.delete(categoryEntries[index])
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 5. Weekly Deficit Summary Card
    private var weeklyDeficitCard: some View {
        Button {
            navigateToHistory = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appSuccess)
                        Text("DÉFICIT CALÓRICO SEMANAL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
                
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Déficit semanal")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        Text("\(weeklyTotalDeficit > 0 ? "+" : "")\(formatKcal(weeklyTotalDeficit)) kcal")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(weeklyTotalDeficit < 0 ? .appSuccess : (weeklyTotalDeficit > 0 ? .appError : .appTextPrimary))
                    }
                    
                    Divider()
                        .frame(height: 32)
                        .background(Color.appBorder.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Promedio diario")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        Text("\(weeklyAverageDeficit > 0 ? "+" : "")\(formatKcal(weeklyAverageDeficit)) kcal/d")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(weeklyAverageDeficit < 0 ? .appSuccess : (weeklyAverageDeficit > 0 ? .appError : .appTextPrimary))
                    }
                }
                
                // Fila de 7 barras verticales (L M X J V S D)
                HStack(alignment: .bottom, spacing: 8) {
                    let dayLetters = ["L", "M", "X", "J", "V", "S", "D"]
                    ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, date in
                        let dayKey = Calendar.current.startOfDay(for: date)
                        let deficit = weekDeficits[dayKey]
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.currentDate)
                        let isFuture = date > Calendar.current.startOfDay(for: Date())
                        
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                // Background pill track
                                Capsule()
                                    .fill(Color.appSurfaceElevated)
                                    .frame(width: 28, height: 42)
                                
                                if let def = deficit, !isFuture {
                                    let barHeight = min(38.0, max(12.0, abs(CGFloat(def)) / 35.0))
                                    Capsule()
                                        .fill(def < 0 ? Color.appSuccess : Color.appError)
                                        .frame(width: 28, height: barHeight)
                                } else if isSelected {
                                    Capsule()
                                        .stroke(Color.appTerracotta, lineWidth: 1.5)
                                        .frame(width: 28, height: 42)
                                }
                            }
                            
                            Text(index < dayLetters.count ? dayLetters[index] : "")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .appTerracotta : .appTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 6. Activity Section (Apple Watch + Hevy)
    private var activitySection: some View {
        VStack(spacing: 12) {
            // Tarjeta de Actividad (Anillos Apple Watch)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.watchMoveRed)
                        Text("ACTIVIDAD APPLE WATCH")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(formatKcal(Int(viewModel.activeCaloriesBurned)))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        Text("kcal activas")
                            .font(.caption.bold())
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Basales: \(formatKcal(Int(viewModel.basalCaloriesBurned))) kcal · Ajuste -15%")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                        
                        Text("\(Int(viewModel.exerciseMinutes))m ejercicio · \(Int(viewModel.standHours))h de pie")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
                
                // Anillos concéntricos Apple Watch
                AppleWatchRingsView(
                    moveProgress: viewModel.moveGoal > 0 ? (viewModel.moveKcal / viewModel.moveGoal) : 0,
                    exerciseProgress: viewModel.exerciseGoal > 0 ? (viewModel.exerciseMinutes / viewModel.exerciseGoal) : 0,
                    standProgress: viewModel.standGoal > 0 ? (viewModel.standHours / viewModel.standGoal) : 0,
                    size: 74,
                    ringThickness: 6.5,
                    ringSpacing: 2.5
                )
            }
            .padding(16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
            
            // Tarjeta de Hevy
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(todayWorkout != nil ? .appCyan : .appTextSecondary)
                    .frame(width: 38, height: 38)
                    .background((todayWorkout != nil ? Color.appCyan : Color.appTextSecondary).opacity(0.18))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    if let workout = todayWorkout {
                        Text(workout.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text("\(formatVolume(workout.totalVolumeKg)) kg levantados hoy")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    } else {
                        Text("Sin entreno registrado hoy")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.appTextSecondary)
                        Text("Conectado con Hevy")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            .padding(14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helpers & Data Loading
    private func loadWeeklyDeficits() async {
        guard !isLoadingWeekDeficits else { return }
        isLoadingWeekDeficits = true
        
        let days = currentWeekDays
        for day in days {
            let startDay = Calendar.current.startOfDay(for: day)
            if weekDeficits[startDay] == nil {
                do {
                    let (active, basal) = try await HealthKitManager.shared.fetchEnergyBurned(for: startDay)
                    if active > 0 || basal > 0 {
                        let adjustedBurned = Int((active * 0.85) + basal)
                        let dayEntries = allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: startDay) }
                        let dayCalories = dayEntries.reduce(0) { $0 + $1.calories }
                        weekDeficits[startDay] = dayCalories - adjustedBurned
                    }
                } catch {
                    // Ignorar errores en días específicos
                }
            }
        }
        
        isLoadingWeekDeficits = false
    }
    
    private func formatKcal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func formatDouble(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
    
    private func formatVolume(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
}
