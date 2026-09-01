import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // Tipos de datos que queremos leer
    private let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
    private let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    
    var isAuthorized: Bool = false
    
    private init() {}
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }
        
        // Tipos de muestra válidos para autorización en HealthKit
        var typesToRead: Set<HKObjectType> = [
            activeEnergyType,
            basalEnergyType,
            stepCountType
        ]
        
        if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            typesToRead.insert(exerciseType)
        }
        if let standHourType = HKObjectType.categoryType(forIdentifier: .appleStandHour) {
            typesToRead.insert(standHourType)
        }
        // NOTA: HKActivitySummaryType NO se pasa a requestAuthorization porque HealthKit
        // autoriza los resúmenes automáticamente a partir de los tipos de energía/ejercicio/pie individuales.
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        isAuthorized = true
    }
    
    func fetchEnergyBurned(for date: Date) async throws -> (active: Double, basal: Double) {
        guard isAuthorized else { return (0, 0) }
        
        let active = try await fetchQuantity(for: activeEnergyType, unit: HKUnit.kilocalorie(), date: date)
        let basal = try await fetchQuantity(for: basalEnergyType, unit: HKUnit.kilocalorie(), date: date)
        
        return (active, basal)
    }
    
    func fetchStepCount(for date: Date) async throws -> Int {
        guard isAuthorized else { return 0 }
        let count = try await fetchQuantity(for: stepCountType, unit: HKUnit.count(), date: date)
        return Int(count)
    }
    
    func fetchActivitySummary(for date: Date) async throws -> (moveKcal: Double, moveGoal: Double, exerciseMin: Double, exerciseGoal: Double, standHours: Double, standGoal: Double) {
        guard isAuthorized else {
            return (0, 600, 0, 30, 0, 12)
        }
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .era], from: date)
        dateComponents.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let summary = summaries?.first else {
                    continuation.resume(returning: (0, 600, 0, 30, 0, 12))
                    return
                }
                
                let move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
                let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                let exercise = summary.appleExerciseTime.doubleValue(for: .minute())
                let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                let stand = summary.appleStandHours.doubleValue(for: .count())
                let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                
                continuation.resume(returning: (
                    move,
                    moveGoal > 0 ? moveGoal : 600,
                    exercise,
                    exerciseGoal > 0 ? exerciseGoal : 30,
                    stand,
                    standGoal > 0 ? standGoal : 12
                ))
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func fetchQuantity(for type: HKQuantityType, unit: HKUnit, date: Date) async throws -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        // 1. Obtener las fuentes disponibles para evitar datos duplicados
        let sources = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Set<HKSource>, Error>) in
            let sourceQuery = HKSourceQuery(sampleType: type, samplePredicate: datePredicate) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result ?? [])
            }
            healthStore.execute(sourceQuery)
        }
        
        // 2. Filtrar preferiblemente por el Apple Watch (todas las fuentes de Watch para no perder datos si hay reemplazo), o hacer fallback a la app Salud
        var sourcePredicate: NSPredicate?
        let watchSources = sources.filter { $0.name.localizedCaseInsensitiveContains("watch") }
        if !watchSources.isEmpty {
            sourcePredicate = HKQuery.predicateForObjects(from: Set(watchSources))
        } else if let healthSource = sources.first(where: { $0.bundleIdentifier == "com.apple.Health" }) {
            sourcePredicate = HKQuery.predicateForObjects(from: healthSource)
        }
        
        let finalPredicate: NSPredicate
        if let sourcePredicate = sourcePredicate {
            finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, sourcePredicate])
        } else {
            finalPredicate = datePredicate
        }
        
        // 3. Realizar la consulta de estadísticas con el predicado filtrado
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: finalPredicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
}
