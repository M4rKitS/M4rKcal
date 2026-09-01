import SwiftUI

struct CategorySectionView: View {
    let category: MealCategory
    let entries: [MealEntry]
    let date: Date
    let onAdd: () -> Void
    let onDelete: (IndexSet) -> Void
    
    @State private var isExpanded: Bool = true
    
    var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    var totalProteins: Double {
        entries.reduce(0) { $0 + $1.proteins }
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                if !entries.isEmpty {
                    Divider()
                        .background(Color.appBorder.opacity(0.4))
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                MealRowView(entry: entry)
                                
                                Button {
                                    onDelete(IndexSet(integer: index))
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appTextSecondary.opacity(0.6))
                                        .padding(.leading, 8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            
                            if index < entries.count - 1 {
                                Divider()
                                    .background(Color.appBorder.opacity(0.25))
                            }
                        }
                    }
                    .padding(.bottom, 4)
                } else {
                    Text("Aún no has añadido nada aquí hoy")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Icono circular coloreado
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(category.color)
                    .frame(width: 32, height: 32)
                    .background(category.color.opacity(0.18))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    if totalCalories > 0 || totalProteins > 0 {
                        HStack(spacing: 6) {
                            Text("\(totalCalories) kcal")
                                .font(.caption.bold())
                                .foregroundColor(.appTerracotta)
                            Text("·")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                            Text("\(totalProteins, specifier: "%.1f")g prot")
                                .font(.caption.bold())
                                .foregroundColor(.appCyan)
                        }
                    } else {
                        Text("Sin registrar")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
                
                // Botón rápido de añadir con separación previa al chevron
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appTerracotta)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .padding(.vertical, 6)
        }
        .tint(.appTextSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appBorder.opacity(0.35), lineWidth: 1)
        )
    }
}
