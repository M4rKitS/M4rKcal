import SwiftUI

struct WeekDaySelectorView: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    
    private var currentWeekDays: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Lunes
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    private let dayNames = ["L", "M", "X", "J", "V", "S", "D"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday = Calendar.current.isDateInToday(date)
                let isFuture = date > Calendar.current.startOfDay(for: Date())
                let dayNumber = Calendar.current.component(.day, from: date)
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    selectedDate = date
                    onDateChanged(date)
                } label: {
                    VStack(spacing: 6) {
                        Text(index < dayNames.count ? dayNames[index] : "")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                        
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color.appTerracotta)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color.appTerracotta.opacity(0.35), radius: 6, x: 0, y: 2)
                            } else if isToday {
                                Circle()
                                    .stroke(Color.appTerracotta.opacity(0.6), lineWidth: 1.5)
                                    .frame(width: 36, height: 36)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 36, height: 36)
                            }
                            
                            Text("\(dayNumber)")
                                .font(.system(size: 15, weight: isSelected ? .bold : (isToday ? .semibold : .regular), design: .rounded))
                                .foregroundColor(
                                    isSelected ? .white :
                                    (isFuture ? .appTextSecondary.opacity(0.4) : .appTextPrimary)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        WeekDaySelectorView(selectedDate: .constant(Date()), onDateChanged: { _ in })
            .padding()
            .background(Color.appSurface)
            .cornerRadius(16)
    }
}
