import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error al solicitar permisos de notificación: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleWeighInReminder(lastWeighInDate: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Toca revisión"
        content.body = "Mañana te toca registrar tu peso y medidas en M4rkcal"
        content.sound = .default
        
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: 13, to: lastWeighInDate) else { return }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "weighInReminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error al programar recordatorio de pesaje: \(error.localizedDescription)")
            }
        }
    }
}
