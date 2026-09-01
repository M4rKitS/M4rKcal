import SwiftUI
import SwiftData

struct AddMealSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var category: MealCategory
    var date: Date
    
    @State private var name: String = ""
    @State private var caloriesPer100gStr: String = ""
    @State private var proteinPer100gStr: String = ""
    @State private var gramsStr: String = "100"
    @State private var saveAsFavorite: Bool = false
    @State private var isFavoritesExpanded: Bool = false
    
    @State private var showingScanner = false
    @State private var isScanningLoading = false
    @State private var scanAlertMessage: String?
    
    enum Field {
        case name, calories, proteins, grams
    }
    @FocusState private var focusedField: Field?
    
    // Consultas
    @Query(sort: \FavoriteFood.name) private var favorites: [FavoriteFood]
    @Query(sort: \MealEntry.date, order: .reverse) private var recentEntries: [MealEntry]
    
    private var uniqueRecents: [MealEntry] {
        var seenNames = Set<String>()
        var result = [MealEntry]()
        
        for entry in recentEntries {
            let normalizedName = entry.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !seenNames.contains(normalizedName) {
                seenNames.insert(normalizedName)
                result.append(entry)
                if result.count >= 8 { break }
            }
        }
        return result
    }
    
    private var calculatedCalories: Int {
        let cal100 = Double(caloriesPer100gStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let grams = Double(gramsStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        return Int((cal100 / 100.0) * grams)
    }
    
    private var calculatedProteins: Double {
        let prot100 = Double(proteinPer100gStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let grams = Double(gramsStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        return (prot100 / 100.0) * grams
    }
    
    // Feedback háptico
    private let hapticFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Accesos Rápidos")) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(.appTerracotta)
                            Text("Escanear código de barras")
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    
                    if !favorites.isEmpty {
                        DisclosureGroup(
                            isExpanded: $isFavoritesExpanded,
                            content: {
                                ForEach(favorites) { fav in
                                    Button(action: {
                                        fillFromFavorite(fav)
                                        isFavoritesExpanded = false
                                    }) {
                                        HStack {
                                            Text(fav.name)
                                                .foregroundColor(.appTextPrimary)
                                            Spacer()
                                            Text("\(formatDouble(fav.caloriesPer100g)) kcal/100g")
                                                .font(.subheadline)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.appWarning)
                                    Text("Favoritos (\(favorites.count))")
                                        .fontWeight(.semibold)
                                }
                            }
                        )
                    }
                    
                    if !uniqueRecents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recientes")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(uniqueRecents) { recent in
                                        Button(action: {
                                            fillFromRecent(recent)
                                        }) {
                                            Text("\(recent.name)")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.appTextPrimary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.appSurfaceElevated)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    TextField("Nombre del alimento o plato", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .focused($focusedField, equals: .name)
                    
                    HStack {
                        Text("Calorías / 100g")
                        Spacer()
                        TextField("0", text: $caloriesPer100gStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .calories)
                            .multilineTextAlignment(.trailing)
                        Text("kcal").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Proteínas / 100g")
                        Spacer()
                        TextField("0.0", text: $proteinPer100gStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .proteins)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Text("Gramos consumidos")
                        Spacer()
                        TextField("100", text: $gramsStr)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .grams)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundColor(.appTextSecondary)
                    }
                    
                    HStack {
                        Spacer()
                        Text("Total: \(calculatedCalories) kcal · \(calculatedProteins, specifier: "%.1f")g proteína")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.appTerracotta)
                            .padding(.vertical, 4)
                        Spacer()
                    }
                    
                    Toggle(isOn: $saveAsFavorite) {
                        Label("Guardar como favorito", systemImage: "star.fill")
                            .foregroundColor(saveAsFavorite ? .appWarning : .appTextPrimary)
                    }
                    .tint(.appWarning)
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(category.color)
                            .frame(width: 24, height: 24)
                            .background(category.color.opacity(0.2))
                            .clipShape(Circle())
                        
                        Text("Detalles de la comida")
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextSecondary)
                            .textCase(nil)
                    }
                }
            }
            .navigationTitle("Añadir a \(category.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        focusedField = nil
                    }
                    .foregroundColor(.appTerracotta)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveMeal()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.appTerracotta)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || caloriesPer100gStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                hapticFeedback.prepare()
            }
        }
        .tint(.appTerracotta)
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView { barcode in
                showingScanner = false
                handleScannedBarcode(barcode)
            }
            .ignoresSafeArea()
            .overlay {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showingScanner = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .alert("Aviso", isPresented: Binding(get: { scanAlertMessage != nil }, set: { if !$0 { scanAlertMessage = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            if let msg = scanAlertMessage {
                Text(msg)
            }
        }
        .overlay {
            if isScanningLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Buscando producto...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        isScanningLoading = true
        Task {
            do {
                if let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                    name = product.name
                    caloriesPer100gStr = formatDouble(product.caloriesPer100g)
                    proteinPer100gStr = formatDouble(product.proteinPer100g)
                    focusedField = .grams
                } else {
                    scanAlertMessage = "Producto no encontrado en la base de datos. Puedes introducirlo manualmente."
                }
            } catch {
                scanAlertMessage = "Error de conexión al buscar el producto."
            }
            isScanningLoading = false
        }
    }
    
    private func fillFromFavorite(_ fav: FavoriteFood) {
        self.name = fav.name
        self.caloriesPer100gStr = formatDouble(fav.caloriesPer100g)
        self.proteinPer100gStr = formatDouble(fav.proteinPer100g)
        self.gramsStr = "100"
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func fillFromRecent(_ recent: MealEntry) {
        self.name = recent.name
        self.caloriesPer100gStr = formatDouble(recent.caloriesPer100g)
        self.proteinPer100gStr = formatDouble(recent.proteinPer100g)
        self.gramsStr = formatDouble(recent.gramsConsumed)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func formatDouble(_ val: Double) -> String {
        return val.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", val) : String(val)
    }
    
    private func saveMeal() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cal100 = Double(caloriesPer100gStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let prot100 = Double(proteinPer100gStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let grams = Double(gramsStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        let finalKcal = Int((cal100 / 100.0) * grams)
        let finalProt = (prot100 / 100.0) * grams
        
        let newEntry = MealEntry(
            name: cleanName,
            calories: finalKcal,
            proteins: finalProt,
            caloriesPer100g: cal100,
            proteinPer100g: prot100,
            gramsConsumed: grams,
            date: date,
            category: category
        )
        
        modelContext.insert(newEntry)
        
        if saveAsFavorite {
            let normalizedName = cleanName.lowercased()
            if !favorites.contains(where: { $0.name.lowercased() == normalizedName }) {
                let newFav = FavoriteFood(name: cleanName, caloriesPer100g: cal100, proteinPer100g: prot100)
                modelContext.insert(newFav)
            }
        }
        
        hapticFeedback.notificationOccurred(.success)
        dismiss()
    }
}
