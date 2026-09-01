import SwiftUI

struct MealRowView: View {
    let entry: MealEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appTextPrimary)
                
                if entry.gramsConsumed > 0 {
                    Text("\(formatGrams(entry.gramsConsumed))g")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.calories) kcal")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.appTerracotta)
                
                if entry.proteins > 0 {
                    Text("\(entry.proteins, specifier: "%.1f")g prot")
                        .font(.caption.bold())
                        .foregroundColor(.appCyan)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatGrams(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}
