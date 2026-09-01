import SwiftUI
import HealthKit
import Observation

@Observable
final class DashboardViewModel {
    var currentDate: Date = Calendar.current.startOfDay(for: Date())
    
    // HealthKit properties
    var activeCaloriesBurned: Double = 0.0
    var basalCaloriesBurned: Double = 0.0
    var stepCount: Int = 0
    
    // Apple Watch Rings Summary
    var moveKcal: Double = 0.0
    var moveGoal: Double = 600.0
    var exerciseMinutes: Double = 0.0
    var exerciseGoal: Double = 30.0
    var standHours: Double = 0.0
    var standGoal: Double = 12.0
    
    var healthKitAuthorized: Bool = false
    var healthKitError: String?
    
    var totalCaloriesBurned: Int {
        Int(activeCaloriesBurned + basalCaloriesBurned)
    }
    
    // Funciones de navegación de fecha (día anterior, día siguiente, hoy, seleccionar fecha)
    func selectDate(_ date: Date) {
        currentDate = Calendar.current.startOfDay(for: date)
        Task { await loadHealthData() }
    }
    
    func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
            currentDate = Calendar.current.startOfDay(for: newDate)
            Task { await loadHealthData() }
        }
    }
    
    func nextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
            currentDate = Calendar.current.startOfDay(for: newDate)
            Task { await loadHealthData() }
        }
    }
    
    func goToToday() {
        currentDate = Calendar.current.startOfDay(for: Date())
        Task { await loadHealthData() }
    }
    
    func currentWeekDays() -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Lunes
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    func loadHealthData() async {
        DispatchQueue.main.async {
            self.healthKitError = nil
        }
        
        // 1. Asegurar autorización
        if !HealthKitManager.shared.isAuthorized {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                DispatchQueue.main.async {
                    self.healthKitAuthorized = true
                }
            } catch {
                print("Error pidiendo autorización de HealthKit: \(error.localizedDescription)")
            }
        }
        
        // 2. Cargar Energía (Calorías activas y basales del Apple Watch)
        do {
            let energy = try await HealthKitManager.shared.fetchEnergyBurned(for: currentDate)
            DispatchQueue.main.async {
                // Ajuste exacto del -15% únicamente a las calorías activas
                self.activeCaloriesBurned = energy.active * 0.85
                self.basalCaloriesBurned = energy.basal
                self.moveKcal = self.activeCaloriesBurned
            }
        } catch {
            DispatchQueue.main.async {
                self.healthKitError = "Sin datos de Apple Watch"
                self.activeCaloriesBurned = 0.0
                self.basalCaloriesBurned = 0.0
            }
            print("Error cargando energía de HealthKit: \(error.localizedDescription)")
        }
        
        // 3. Cargar Pasos
        do {
            let steps = try await HealthKitManager.shared.fetchStepCount(for: currentDate)
            DispatchQueue.main.async {
                self.stepCount = steps
            }
        } catch {
            DispatchQueue.main.async {
                self.stepCount = 0
            }
            print("Error cargando pasos de HealthKit: \(error.localizedDescription)")
        }
        
        // 4. Cargar Resumen de Anillos de Actividad
        do {
            let activity = try await HealthKitManager.shared.fetchActivitySummary(for: currentDate)
            DispatchQueue.main.async {
                if activity.moveKcal > 0 {
                    self.moveKcal = activity.moveKcal * 0.85
                }
                self.moveGoal = activity.moveGoal
                self.exerciseMinutes = activity.exerciseMin
                self.exerciseGoal = activity.exerciseGoal
                self.standHours = activity.standHours
                self.standGoal = activity.standGoal
            }
        } catch {
            DispatchQueue.main.async {
                self.exerciseMinutes = 0
                self.standHours = 0
            }
            print("Error cargando resumen de actividad: \(error.localizedDescription)")
        }
    }
}
