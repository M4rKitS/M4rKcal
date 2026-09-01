import SwiftUI
import SwiftData

struct QuickScanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingScanner: Bool = true
    @State private var isScanningLoading: Bool = false
    @State private var scanAlertMessage: String?
    
    @State private var name: String = ""
    @State private var caloriesPer100gStr: String = ""
    @State private var proteinPer100gStr: String = ""
    @State private var gramsStr: String = "100"
    @State private var selectedCategory: MealCategory = .comida
    @State private var date: Date = Date()
    @State private var saveAsFavorite: Bool = false
    
    @Query(sort: \FavoriteFood.name) private var favorites: [FavoriteFood]
    
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
    
    private let hapticFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationStack {
            Form {
                if !name.isEmpty {
                    Section("Producto Detectado") {
                        TextField("Nombre", text: $name)
                        
                        Picker("Categoría", selection: $selectedCategory) {
                            ForEach(MealCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                        
                        HStack {
                            Text("Calorías / 100g")
                            Spacer()
                            TextField("0", text: $caloriesPer100gStr)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("kcal").foregroundColor(.appTextSecondary)
                        }
                        
                        HStack {
                            Text("Proteínas / 100g")
                            Spacer()
                            TextField("0.0", text: $proteinPer100gStr)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.appTextSecondary)
                        }
                        
                        HStack {
                            Text("Gramos consumidos")
                            Spacer()
                            TextField("100", text: $gramsStr)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.appTextSecondary)
                        }
                        
                        HStack {
                            Spacer()
                            Text("Total: \(calculatedCalories) kcal · \(calculatedProteins, specifier: "%.1f")g proteína")
                                .font(.subheadline.bold())
                                .foregroundColor(.appTerracotta)
                                .padding(.vertical, 4)
                            Spacer()
                        }
                    }
                    
                    Section {
                        Button {
                            showingScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Escanear otro código")
                            }
                            .foregroundColor(.appTerracotta)
                        }
                    }
                } else {
                    Section {
                        Button {
                            showingScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Abrir escáner de código de barras")
                            }
                            .foregroundColor(.appTerracotta)
                        }
                    }
                }
            }
            .navigationTitle("Escanear Alimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
                
                if !name.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            saveScannedMeal()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.appTerracotta)
                    }
                }
            }
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
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        isScanningLoading = true
        Task {
            do {
                if let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                    name = product.name
                    caloriesPer100gStr = formatDouble(product.caloriesPer100g)
                    proteinPer100gStr = formatDouble(product.proteinPer100g)
                } else {
                    scanAlertMessage = "Producto no encontrado en Open Food Facts. Puedes introducir los datos manualmente."
                }
            } catch {
                scanAlertMessage = "Error de conexión al buscar el producto."
            }
            isScanningLoading = false
        }
    }
    
    private func formatDouble(_ val: Double) -> String {
        return val.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", val) : String(val)
    }
    
    private func saveScannedMeal() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
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
            category: selectedCategory
        )
        
        modelContext.insert(newEntry)
        hapticFeedback.notificationOccurred(.success)
        dismiss()
    }
}
