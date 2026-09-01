import SwiftUI
import SwiftData

struct EditMeasurementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    var weightEntry: WeightEntry?
    var bodyMeasurement: BodyMeasurement?
    
    @State private var weightStr: String = ""
    @State private var waistStr: String = ""
    @State private var chestStr: String = ""
    @State private var thighStr: String = ""
    @State private var hipStr: String = ""
    
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Peso corporal")) {
                HStack {
                    Text("Peso")
                    Spacer()
                    TextField("Ej. 70.5", text: $weightStr)
                        .keyboardType(.decimalPad)
                        .focused($isKeyboardFocused)
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
                        .focused($isKeyboardFocused)
                        .multilineTextAlignment(.trailing)
                    Text("cm").foregroundColor(.appTextSecondary)
                }
                
                HStack {
                    Text("Pecho")
                    Spacer()
                    TextField("Ej. 95.0", text: $chestStr)
                        .keyboardType(.decimalPad)
                        .focused($isKeyboardFocused)
                        .multilineTextAlignment(.trailing)
                    Text("cm").foregroundColor(.appTextSecondary)
                }
                
                HStack {
                    Text("Muslo")
                    Spacer()
                    TextField("Ej. 55.0", text: $thighStr)
                        .keyboardType(.decimalPad)
                        .focused($isKeyboardFocused)
                        .multilineTextAlignment(.trailing)
                    Text("cm").foregroundColor(.appTextSecondary)
                }
                
                HStack {
                    Text("Cadera")
                    Spacer()
                    TextField("Ej. 98.0", text: $hipStr)
                        .keyboardType(.decimalPad)
                        .focused($isKeyboardFocused)
                        .multilineTextAlignment(.trailing)
                    Text("cm").foregroundColor(.appTextSecondary)
                }
            }
        }
        .navigationTitle(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_ES"))))
        .navigationBarTitleDisplayMode(.inline)
        .tint(.appTerracotta)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    isKeyboardFocused = false
                }
                .foregroundColor(.appTerracotta)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Guardar") {
                    saveChanges()
                }
                .fontWeight(.bold)
                .foregroundColor(.appTerracotta)
            }
        }
        .onAppear {
            if let weight = weightEntry?.weightKg {
                weightStr = String(format: "%g", weight)
            }
            if let waist = bodyMeasurement?.waistCm {
                waistStr = String(format: "%g", waist)
            }
            if let chest = bodyMeasurement?.chestCm {
                chestStr = String(format: "%g", chest)
            }
            if let thigh = bodyMeasurement?.thighCm {
                thighStr = String(format: "%g", thigh)
            }
            if let hip = bodyMeasurement?.hipCm {
                hipStr = String(format: "%g", hip)
            }
        }
    }
    
    private func saveChanges() {
        let cleanWeight = Double(weightStr.replacingOccurrences(of: ",", with: "."))
        let cleanWaist = Double(waistStr.replacingOccurrences(of: ",", with: "."))
        let cleanChest = Double(chestStr.replacingOccurrences(of: ",", with: "."))
        let cleanThigh = Double(thighStr.replacingOccurrences(of: ",", with: "."))
        let cleanHip = Double(hipStr.replacingOccurrences(of: ",", with: "."))
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        // Guardar o actualizar Peso
        if let weightVal = cleanWeight {
            if let existingWeight = weightEntry {
                existingWeight.weightKg = weightVal
            } else {
                let newWeight = WeightEntry(date: startOfDay, weightKg: weightVal)
                modelContext.insert(newWeight)
            }
        } else if let existingWeight = weightEntry {
            modelContext.delete(existingWeight)
        }
        
        // Guardar o actualizar Medidas
        let hasAnyMeasurement = cleanWaist != nil || cleanChest != nil || cleanThigh != nil || cleanHip != nil
        if hasAnyMeasurement {
            if let existingMeasurement = bodyMeasurement {
                existingMeasurement.waistCm = cleanWaist
                existingMeasurement.chestCm = cleanChest
                existingMeasurement.thighCm = cleanThigh
                existingMeasurement.hipCm = cleanHip
            } else {
                let newMeasurement = BodyMeasurement(
                    date: startOfDay,
                    waistCm: cleanWaist,
                    chestCm: cleanChest,
                    thighCm: cleanThigh,
                    hipCm: cleanHip
                )
                modelContext.insert(newMeasurement)
            }
        } else if let existingMeasurement = bodyMeasurement {
            modelContext.delete(existingMeasurement)
        }
        
        dismiss()
    }
}
