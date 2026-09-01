import SwiftUI
import SwiftData
import Charts

struct WeeklyDeficitSummary: Identifiable {
    let id: Date
    let startDate: Date
    let endDate: Date
    let totalDeficit: Int
    let daysCount: Int
}

struct MonthlyDeficitSummary: Identifiable {
    let id: Date
    let date: Date
    let totalDeficit: Int
    let daysCount: Int
}

struct WeightAndMeasurementsRecord: Identifiable {
    var id: Date { date }
    let date: Date
    var weightEntry: WeightEntry?
    var bodyMeasurement: BodyMeasurement?
    
    var summaryText: String {
        var parts: [String] = []
        if let weight = weightEntry?.weightKg {
            parts.append("\(String(format: "%g", weight)) kg")
        }
        var measurementParts: [String] = []
        if let waist = bodyMeasurement?.waistCm {
            measurementParts.append("Cintura \(String(format: "%g", waist))cm")
        }
        if let chest = bodyMeasurement?.chestCm {
            measurementParts.append("Pecho \(String(format: "%g", chest))cm")
        }
        if let thigh = bodyMeasurement?.thighCm {
            measurementParts.append("Muslo \(String(format: "%g", thigh))cm")
        }
        if let hip = bodyMeasurement?.hipCm {
            measurementParts.append("Cadera \(String(format: "%g", hip))cm")
        }
        if !measurementParts.isEmpty {
            parts.append(measurementParts.joined(separator: ", "))
        }
        return parts.joined(separator: " · ")
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.date, order: .reverse) private var allEntries: [MealEntry]
    @Query(sort: \WeightEntry.date, order: .forward) private var weightEntries: [WeightEntry]
    @Query(sort: \BodyMeasurement.date, order: .forward) private var bodyMeasurements: [BodyMeasurement]
    
    // Estados de colapso para cada sección
    @State private var isWeightAndMeasurementsExpanded: Bool = false
    @State private var isRecordsExpanded: Bool = false
    @State private var isDeficitExpanded: Bool = false
    @State private var isWeeklyExpanded: Bool = false
    @State private var isMonthlyExpanded: Bool = false
    @State private var isMealsExpanded: Bool = false
    
    @State private var selectedDate: Date?
    @State private var selectedDeficitDate: Date?
    @State private var dailyDeficits: [Date: Int] = [:]
    @State private var isFetchingDeficits = false
    
    private var weightDomain: ClosedRange<Double> {
        let weights = weightEntries.map { $0.weightKg }
        guard let min = weights.min(), let max = weights.max() else {
            return 0...100
        }
        if min == max {
            return (min - 10)...(max + 10)
        }
        return (min - 5)...(max + 5)
    }
    
    private var hasMeasurementsData: Bool {
        bodyMeasurements.contains { $0.waistCm != nil || $0.chestCm != nil || $0.thighCm != nil || $0.hipCm != nil }
    }
    
    // Registros combinados de peso y medidas agrupados por fecha
    private var combinedRecords: [WeightAndMeasurementsRecord] {
        var recordsByDate: [Date: WeightAndMeasurementsRecord] = [:]
        
        for entry in weightEntries {
            let day = Calendar.current.startOfDay(for: entry.date)
            recordsByDate[day, default: WeightAndMeasurementsRecord(date: day, weightEntry: nil, bodyMeasurement: nil)].weightEntry = entry
        }
        
        for measurement in bodyMeasurements {
            let day = Calendar.current.startOfDay(for: measurement.date)
            recordsByDate[day, default: WeightAndMeasurementsRecord(date: day, weightEntry: nil, bodyMeasurement: nil)].bodyMeasurement = measurement
        }
        
        return recordsByDate.values.sorted { $0.date > $1.date }
    }
    
    // Agrupamos las comidas por día localmente
    var groupedEntries: [(Date, [MealEntry])] {
        let grouped = Dictionary(grouping: allEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // Resumen semanal agrupado por semana ISO (lunes a domingo)
    private var weeklyDeficitSummaries: [WeeklyDeficitSummary] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Lunes
        calendar.locale = Locale(identifier: "es_ES")
        
        var groups: [Date: [Int]] = [:]
        
        for (date, deficit) in dailyDeficits {
            if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
                let startOfWeek = calendar.startOfDay(for: interval.start)
                groups[startOfWeek, default: []].append(deficit)
            }
        }
        
        return groups.map { startOfWeek, deficits in
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            let total = deficits.reduce(0, +)
            return WeeklyDeficitSummary(
                id: startOfWeek,
                startDate: startOfWeek,
                endDate: endOfWeek,
                totalDeficit: total,
                daysCount: deficits.count
            )
        }.sorted { $0.startDate > $1.startDate }
    }
    
    // Resumen mensual agrupado por mes
    private var monthlyDeficitSummaries: [MonthlyDeficitSummary] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "es_ES")
        
        var groups: [Date: [Int]] = [:]
        
        for (date, deficit) in dailyDeficits {
            let components = calendar.dateComponents([.year, .month], from: date)
            if let startOfMonth = calendar.date(from: components) {
                groups[startOfMonth, default: []].append(deficit)
            }
        }
        
        return groups.map { startOfMonth, deficits in
            let total = deficits.reduce(0, +)
            return MonthlyDeficitSummary(
                id: startOfMonth,
                date: startOfMonth,
                totalDeficit: total,
                daysCount: deficits.count
            )
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. Evolución del peso y medidas
                Section {
                    DisclosureGroup(isExpanded: $isWeightAndMeasurementsExpanded) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Gráfica de peso
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Peso")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.appTextSecondary)
                                
                                if !weightEntries.isEmpty {
                                    weightChart
                                        .padding(.vertical, 4)
                                } else {
                                    ContentUnavailableView(
                                        "Sin registros de peso",
                                        systemImage: "scalemass",
                                        description: Text("No hay registros de peso.")
                                    )
                                    .frame(height: 120)
                                }
                            }
                            
                            Divider()
                                .background(Color.appBorder.opacity(0.4))
                            
                            // Gráfica de medidas
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Medidas corporales")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.appTextSecondary)
                                
                                if hasMeasurementsData {
                                    measurementsChart
                                        .padding(.vertical, 4)
                                } else {
                                    ContentUnavailableView(
                                        "Sin registros de medidas",
                                        systemImage: "ruler",
                                        description: Text("No hay registros de medidas.")
                                    )
                                    .frame(height: 120)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appCyan)
                                .frame(width: 26, height: 26)
                                .background(Color.appCyan.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("EVOLUCIÓN DEL PESO Y MEDIDAS")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // 2. Registros de peso y medidas
                Section {
                    DisclosureGroup(isExpanded: $isRecordsExpanded) {
                        if !combinedRecords.isEmpty {
                            ForEach(combinedRecords) { record in
                                NavigationLink {
                                    EditMeasurementView(
                                        date: record.date,
                                        weightEntry: record.weightEntry,
                                        bodyMeasurement: record.bodyMeasurement
                                    )
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.date, style: .date)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.appTextPrimary)
                                        if !record.summaryText.isEmpty {
                                            Text(record.summaryText)
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .onDelete(perform: deleteRecord)
                        } else {
                            ContentUnavailableView(
                                "Sin registros guardados",
                                systemImage: "list.bullet.clipboard",
                                description: Text("No hay registros guardados.")
                            )
                            .frame(height: 120)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.clipboard.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appCyan)
                                .frame(width: 26, height: 26)
                                .background(Color.appCyan.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("REGISTROS DE PESO Y MEDIDAS")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // 3. Déficit calórico
                Section {
                    DisclosureGroup(isExpanded: $isDeficitExpanded) {
                        if isFetchingDeficits {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.appTerracotta)
                                Spacer()
                            }
                            .padding(.vertical)
                        } else if !dailyDeficits.isEmpty {
                            deficitChart
                                .padding(.vertical, 4)
                        } else {
                            ContentUnavailableView(
                                "Sin datos de déficit",
                                systemImage: "flame",
                                description: Text("No hay datos de actividad para calcular el déficit.")
                            )
                            .frame(height: 120)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appTerracotta)
                                .frame(width: 26, height: 26)
                                .background(Color.appTerracotta.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("DÉFICIT CALÓRICO")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // 4. Resumen semanal
                Section {
                    DisclosureGroup(isExpanded: $isWeeklyExpanded) {
                        if !weeklyDeficitSummaries.isEmpty {
                            ForEach(weeklyDeficitSummaries) { summary in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatWeekRange(start: summary.startDate, end: summary.endDate))
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.appTextPrimary)
                                        Text("\(summary.daysCount) \(summary.daysCount == 1 ? "día registrado" : "días registrados")")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(summary.totalDeficit > 0 ? "+" : "")\(formatKcal(summary.totalDeficit)) kcal")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(summary.totalDeficit < 0 ? .appSuccess : .appError)
                                }
                                .padding(.vertical, 2)
                            }
                        } else {
                            ContentUnavailableView(
                                "Sin resúmenes semanales",
                                systemImage: "calendar",
                                description: Text("No hay resúmenes semanales.")
                            )
                            .frame(height: 120)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appSuccess)
                                .frame(width: 26, height: 26)
                                .background(Color.appSuccess.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("RESUMEN SEMANAL")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // 5. Resumen mensual
                Section {
                    DisclosureGroup(isExpanded: $isMonthlyExpanded) {
                        if !monthlyDeficitSummaries.isEmpty {
                            ForEach(monthlyDeficitSummaries) { summary in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatMonthYear(summary.date))
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.appTextPrimary)
                                        Text("\(summary.daysCount) \(summary.daysCount == 1 ? "día registrado" : "días registrados")")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(summary.totalDeficit > 0 ? "+" : "")\(formatKcal(summary.totalDeficit)) kcal")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(summary.totalDeficit < 0 ? .appSuccess : .appError)
                                }
                                .padding(.vertical, 2)
                            }
                        } else {
                            ContentUnavailableView(
                                "Sin resúmenes mensuales",
                                systemImage: "calendar.badge.clock",
                                description: Text("No hay resúmenes mensuales.")
                            )
                            .frame(height: 120)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appCyan)
                                .frame(width: 26, height: 26)
                                .background(Color.appCyan.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("RESUMEN MENSUAL")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // 6. Comidas
                Section {
                    DisclosureGroup(isExpanded: $isMealsExpanded) {
                        if !groupedEntries.isEmpty {
                            ForEach(groupedEntries, id: \.0) { (date, entries) in
                                let dailyCalories = entries.reduce(0) { $0 + $1.calories }
                                let dailyProteins = entries.reduce(0) { $0 + $1.proteins }
                                
                                NavigationLink {
                                    HistoryDetailView(date: date, entries: entries)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(date, style: .date)
                                                .font(.headline)
                                                .foregroundColor(.appTextPrimary)
                                            Text("\(entries.count) comidas registradas")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(dailyCalories) kcal")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(.appTerracotta)
                                            Text("\(dailyProteins, specifier: "%.0f")g prot")
                                                .font(.caption.bold())
                                                .foregroundColor(.appCyan)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "Sin comidas registradas",
                                systemImage: "fork.knife",
                                description: Text("No hay comidas registradas.")
                            )
                            .frame(height: 120)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appTerracotta)
                                .frame(width: 26, height: 26)
                                .background(Color.appTerracotta.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text("COMIDAS")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
            }
            .navigationTitle("Historial")
            .tint(.appTerracotta)
            .task(id: groupedEntries.map { $0.0 }) {
                isFetchingDeficits = true
                for (date, entries) in groupedEntries {
                    if dailyDeficits[date] == nil {
                        do {
                            let (active, basal) = try await HealthKitManager.shared.fetchEnergyBurned(for: date)
                            if active > 0 || basal > 0 {
                                let adjustedBurned = Int((active * 0.85) + basal)
                                let dailyCalories = entries.reduce(0) { $0 + $1.calories }
                                dailyDeficits[date] = dailyCalories - adjustedBurned
                            }
                        } catch {
                            // Ignorar días que fallan
                        }
                    }
                }
                isFetchingDeficits = false
            }
            .overlay {
                if allEntries.isEmpty && weightEntries.isEmpty && bodyMeasurements.isEmpty {
                    ContentUnavailableView(
                        "Sin registros",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Tus registros diarios aparecerán aquí.")
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews / Charts
    private var weightChart: some View {
        Chart {
            ForEach(weightEntries) { entry in
                LineMark(
                    x: .value("Fecha", entry.date, unit: .day),
                    y: .value("Peso (kg)", entry.weightKg)
                )
                .foregroundStyle(Color.appCyan)
                .symbol(Circle())
                .interpolationMethod(.catmullRom)
            }
            
            if let selectedDate = selectedDate,
               let entry = weightEntries.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }) {
                RuleMark(x: .value("Selected", entry.date, unit: .day))
                    .foregroundStyle(Color.appBorder)
                    .annotation(position: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.weightKg, specifier: "%.1f") kg")
                                .font(.subheadline.bold())
                                .foregroundColor(.appTextPrimary)
                            Text(entry.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(8)
                        .background(Color.appSurfaceElevated)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
            }
        }
        .chartXAxis {
            let dates = weightEntries.map { Calendar.current.startOfDay(for: $0.date) }
            AxisMarks(values: dates) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(Color.appBorder.opacity(0.4))
                AxisTick()
                    .foregroundStyle(Color.appBorder)
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .chartYScale(domain: weightDomain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geometry[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
        .frame(height: 200)
        .padding(.top, 40)
        .padding(.bottom, 10)
    }
    
    private var measurementsChart: some View {
        Chart {
            ForEach(bodyMeasurements) { measurement in
                if let waist = measurement.waistCm {
                    LineMark(
                        x: .value("Fecha", measurement.date, unit: .day),
                        y: .value("Valor (cm)", waist)
                    )
                    .foregroundStyle(by: .value("Medida", "Cintura"))
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                }
                if let chest = measurement.chestCm {
                    LineMark(
                        x: .value("Fecha", measurement.date, unit: .day),
                        y: .value("Valor (cm)", chest)
                    )
                    .foregroundStyle(by: .value("Medida", "Pecho"))
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                }
                if let thigh = measurement.thighCm {
                    LineMark(
                        x: .value("Fecha", measurement.date, unit: .day),
                        y: .value("Valor (cm)", thigh)
                    )
                    .foregroundStyle(by: .value("Medida", "Muslo"))
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                }
                if let hip = measurement.hipCm {
                    LineMark(
                        x: .value("Fecha", measurement.date, unit: .day),
                        y: .value("Valor (cm)", hip)
                    )
                    .foregroundStyle(by: .value("Medida", "Cadera"))
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartXAxis {
            let dates = bodyMeasurements.map { Calendar.current.startOfDay(for: $0.date) }
            AxisMarks(values: dates) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(Color.appBorder.opacity(0.4))
                AxisTick()
                    .foregroundStyle(Color.appBorder)
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .frame(height: 200)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    private var deficitChart: some View {
        Chart {
            RuleMark(y: .value("Cero", 0))
                .foregroundStyle(Color.appBorder)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            
            ForEach(dailyDeficits.sorted(by: { $0.key < $1.key }), id: \.key) { date, deficit in
                LineMark(
                    x: .value("Fecha", date, unit: .day),
                    y: .value("Déficit (kcal)", deficit)
                )
                .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Fecha", date, unit: .day),
                    y: .value("Déficit (kcal)", deficit)
                )
                .foregroundStyle(deficit < 0 ? Color.appSuccess : Color.appError)
                .symbol(Circle())
                .symbolSize(40)
            }
            
            if let selectedDeficitDate = selectedDeficitDate,
               let closestDate = dailyDeficits.keys.min(by: { abs($0.timeIntervalSince(selectedDeficitDate)) < abs($1.timeIntervalSince(selectedDeficitDate)) }),
               let deficit = dailyDeficits[closestDate] {
                RuleMark(x: .value("Selected", closestDate, unit: .day))
                    .foregroundStyle(Color.appBorder)
                    .annotation(position: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(deficit > 0 ? "+" : "")\(formatKcal(deficit)) kcal")
                                .font(.subheadline.bold())
                                .foregroundColor(deficit < 0 ? .appSuccess : .appError)
                            Text(closestDate.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(8)
                        .background(Color.appSurfaceElevated)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
            }
        }
        .chartXAxis {
            let dates = dailyDeficits.keys.map { Calendar.current.startOfDay(for: $0) }.sorted()
            AxisMarks(values: dates) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(Color.appBorder.opacity(0.4))
                AxisTick()
                    .foregroundStyle(Color.appBorder)
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_ES"))))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geometry[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDeficitDate = date
                                }
                            }
                            .onEnded { _ in
                                selectedDeficitDate = nil
                            }
                    )
            }
        }
        .frame(height: 200)
        .padding(.top, 40)
        .padding(.bottom, 10)
    }
    
    private func deleteRecord(at offsets: IndexSet) {
        for index in offsets {
            let record = combinedRecords[index]
            if let weight = record.weightEntry {
                modelContext.delete(weight)
            }
            if let measurement = record.bodyMeasurement {
                modelContext.delete(measurement)
            }
        }
    }
    
    // MARK: - Helpers
    private func formatKcal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func formatWeekRange(start: Date, end: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.locale = Locale(identifier: "es_ES")
        
        let startMonth = calendar.component(.month, from: start)
        let endMonth = calendar.component(.month, from: end)
        let startYear = calendar.component(.year, from: start)
        let endYear = calendar.component(.year, from: end)
        
        let startDay = calendar.component(.day, from: start)
        let endDay = calendar.component(.day, from: end)
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_ES")
        monthFormatter.dateFormat = "MMM"
        
        let startMonthStr = monthFormatter.string(from: start).replacingOccurrences(of: ".", with: "")
        let endMonthStr = monthFormatter.string(from: end).replacingOccurrences(of: ".", with: "")
        
        if startMonth == endMonth && startYear == endYear {
            return "\(startDay)-\(endDay) \(startMonthStr)"
        } else if startYear == endYear {
            return "\(startDay) \(startMonthStr) - \(endDay) \(endMonthStr)"
        } else {
            return "\(startDay) \(startMonthStr) \(startYear) - \(endDay) \(endMonthStr) \(endYear)"
        }
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}

// Vista de detalle para un día específico
struct HistoryDetailView: View {
    let date: Date
    let entries: [MealEntry]
    
    var body: some View {
        List {
            ForEach(MealCategory.allCases, id: \.self) { category in
                let categoryEntries = entries.filter { $0.category == category }
                if !categoryEntries.isEmpty {
                    Section {
                        ForEach(categoryEntries) { entry in
                            MealRowView(entry: entry)
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(category.color)
                                .frame(width: 26, height: 26)
                                .background(category.color.opacity(0.18))
                                .clipShape(Circle())
                            
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                                .textCase(nil)
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
        }
        .navigationTitle(Text(date, style: .date))
        .navigationBarTitleDisplayMode(.inline)
    }
}
