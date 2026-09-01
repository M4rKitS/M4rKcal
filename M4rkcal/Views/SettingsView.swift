import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [DailyGoal]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    
    @State private var caloriesMinStr: String = ""
    @State private var caloriesMaxStr: String = ""
    @State private var proteinGoalStr: String = ""
    @State private var weightStr: String = ""
    @State private var waistStr: String = ""
    @State private var chestStr: String = ""
    @State private var thighStr: String = ""
    @State private var hipStr: String = ""
    @State private var hevyApiKeyStr: String = ""
    @State private var isSavedFeedback: Bool = false
    
    private var currentGoal: DailyGoal? {
        goals.first
    }
    
    enum Field {
        case caloriasMin
        case caloriasMax
        case proteinas
        case peso
        case cintura
        case pecho
        case muslo
        case cadera
        case hevyApiKey
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mis objetivos")) {
                    HStack {
                        Text("Calorías (Mín)")
                        Spacer()
                        TextField("2700", text: $caloriesMinStr)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .caloriasMin)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: caloriesMinStr) { _, newValue in
                                if let val = Int(newValue), let goal = currentGoal {
                                    goal.caloriesGoalMin = val
                                }
                            }
                        Text("kcal").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Calorías (Máx)")
                        Spacer()
                        TextField("3000", text: $caloriesMaxStr)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .caloriasMax)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: caloriesMaxStr) { _, newValue in
                                if let val = Int(newValue), let goal = currentGoal {
                                    goal.caloriesGoalMax = val
                                }
                            }
                        Text("kcal").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Proteínas")
                        Spacer()
                        TextField("150", text: $proteinGoalStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .proteinas)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: proteinGoalStr) { _, newValue in
                                let cleanStr = newValue.replacingOccurrences(of: ",", with: ".")
                                if let val = Double(cleanStr), let goal = currentGoal {
                                    goal.proteinGoal = val
                                }
                            }
                        Text("g").foregroundColor(.appTextSecondary)
                    }
                }
                
                Section(header: Text("Peso corporal")) {
                    HStack {
                        Text("Peso de hoy")
                        Spacer()
                        TextField("Ej. 70.5", text: $weightStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .peso)
                            .multilineTextAlignment(.trailing)
                        Text("kg").foregroundColor(.appTextSecondary)
                    }
                }
                
                Section(header: Text("Medidas corporales")) {
                    HStack {
                        Text("Cintura")
                        Spacer()
                        TextField("Ej. 80.0", text: $waistStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .cintura)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Pecho")
                        Spacer()
                        TextField("Ej. 95.0", text: $chestStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .pecho)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Muslo")
                        Spacer()
                        TextField("Ej. 55.0", text: $thighStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .muslo)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Cadera")
                        Spacer()
                        TextField("Ej. 98.0", text: $hipStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .cadera)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundColor(.appTextSecondary)
                    }
                }
                
                Section(
                    header: Text("Hevy"),
                    footer: Text("Consigue tu clave en hevy.com/settings?developer (requiere Hevy Pro)")
                ) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.appCyan)
                        SecureField("Pega tu clave de API", text: $hevyApiKeyStr)
                            .focused($focusedField, equals: .hevyApiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section(header: Text("Sincronización")) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.watchMoveRed)
                        Text("Sincronización HealthKit")
                        Spacer()
                        Text(HealthKitManager.shared.isAuthorized ? "Conectado" : "Pendiente")
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Section(footer: Text("M4rkcal guarda tus comidas y medidas de forma segura en tu dispositivo y sincroniza tus calorías quemadas a través de HealthKit y tu Apple Watch.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Ajustes")
            .tint(.appTerracotta)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleSave()
                    } label: {
                        if isSavedFeedback {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Guardado")
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.appSuccess)
                        } else {
                            Text("Guardar")
                                .fontWeight(.bold)
                                .foregroundColor(.appTerracotta)
                        }
                    }
                    .disabled(isSavedFeedback)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        focusedField = nil
                    }
                    .foregroundColor(.appTerracotta)
                }
            }
            .onChange(of: focusedField) { oldValue, newValue in
                let goalFields: [Field] = [.caloriasMin, .caloriasMax, .proteinas]
                let wasInGoals = oldValue.map { goalFields.contains($0) } ?? false
                let isInGoals = newValue.map { goalFields.contains($0) } ?? false
                
                if wasInGoals && !isInGoals {
                    saveGoals()
                }
                
                if oldValue == .peso && newValue != .peso {
                    let cleanStr = weightStr.replacingOccurrences(of: ",", with: ".")
                    if let val = Double(cleanStr) {
                        saveWeight(val)
                    }
                }
                
                let measurementFields: [Field] = [.cintura, .pecho, .muslo, .cadera]
                let wasInMeasurements = oldValue.map { measurementFields.contains($0) } ?? false
                let isInMeasurements = newValue.map { measurementFields.contains($0) } ?? false
                
                if wasInMeasurements && !isInMeasurements {
                    saveBodyMeasurements()
                }
                
                if oldValue == .hevyApiKey && newValue != .hevyApiKey {
                    KeychainHelper.shared.save(hevyApiKeyStr.trimmingCharacters(in: .whitespacesAndNewlines), account: "hevyApiKey")
                }
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                
                let goalMin = currentGoal?.caloriesGoalMin ?? 2700
                let goalMax = currentGoal?.caloriesGoalMax ?? 3000
                let goalProt = currentGoal?.proteinGoal ?? 150.0
                caloriesMinStr = "\(goalMin)"
                caloriesMaxStr = "\(goalMax)"
                proteinGoalStr = String(format: "%g", goalProt)
                
                if let todayWeight = weightEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    weightStr = String(format: "%g", todayWeight.weightKg)
                }
                
                if let todayMeasurements = bodyMeasurements.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    if let waist = todayMeasurements.waistCm { waistStr = String(format: "%g", waist) }
                    if let chest = todayMeasurements.chestCm { chestStr = String(format: "%g", chest) }
                    if let thigh = todayMeasurements.thighCm { thighStr = String(format: "%g", thigh) }
                    if let hip = todayMeasurements.hipCm { hipStr = String(format: "%g", hip) }
                }
                
                hevyApiKeyStr = KeychainHelper.shared.read(account: "hevyApiKey") ?? ""
            }
        }
    }
    
    private func handleSave() {
        saveGoals()
        
        let cleanStr = weightStr.replacingOccurrences(of: ",", with: ".")
        if let val = Double(cleanStr) {
            saveWeight(val)
        }
        
        saveBodyMeasurements()
        
        if !hevyApiKeyStr.isEmpty {
            KeychainHelper.shared.save(hevyApiKeyStr.trimmingCharacters(in: .whitespacesAndNewlines), account: "hevyApiKey")
        }
        
        focusedField = nil
        
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isSavedFeedback = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSavedFeedback = false
                }
            }
        }
    }
    
    private func saveGoals() {
        let cleanProt = Double(proteinGoalStr.replacingOccurrences(of: ",", with: ".")) ?? 150.0
        let minCal = Int(caloriesMinStr) ?? 2700
        let maxCal = Int(caloriesMaxStr) ?? 3000
        
        if let goal = currentGoal {
            goal.caloriesGoalMin = minCal
            goal.caloriesGoalMax = maxCal
            goal.proteinGoal = cleanProt
        } else {
            let newGoal = DailyGoal(
                caloriesGoal: (minCal + maxCal) / 2,
                caloriesGoalMin: minCal,
                caloriesGoalMax: maxCal,
                proteinGoal: cleanProt
            )
            modelContext.insert(newGoal)
        }
    }
    
    private func saveWeight(_ weight: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate: Date
        if let existing = weightEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            existing.weightKg = weight
            savedDate = existing.date
        } else {
            let newEntry = WeightEntry(date: today, weightKg: weight)
            modelContext.insert(newEntry)
            savedDate = newEntry.date
        }
        NotificationManager.shared.scheduleWeighInReminder(lastWeighInDate: savedDate)
    }
    
    private func saveBodyMeasurements() {
        let cleanWaist = Double(waistStr.replacingOccurrences(of: ",", with: "."))
        let cleanChest = Double(chestStr.replacingOccurrences(of: ",", with: "."))
        let cleanThigh = Double(thighStr.replacingOccurrences(of: ",", with: "."))
        let cleanHip = Double(hipStr.replacingOccurrences(of: ",", with: "."))
        
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = bodyMeasurements.first(where: { Calendar.current.isDateInToday($0.date) }) {
            existing.waistCm = cleanWaist
            existing.chestCm = cleanChest
            existing.thighCm = cleanThigh
            existing.hipCm = cleanHip
        } else if cleanWaist != nil || cleanChest != nil || cleanThigh != nil || cleanHip != nil {
            let newEntry = BodyMeasurement(
                date: today,
                waistCm: cleanWaist,
                chestCm: cleanChest,
                thighCm: cleanThigh,
                hipCm: cleanHip
            )
            modelContext.insert(newEntry)
        }
    }
}
