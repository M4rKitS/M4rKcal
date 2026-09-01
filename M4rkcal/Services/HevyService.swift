import Foundation

struct TodayWorkoutSummary {
    let title: String
    let totalVolumeKg: Double
}

final class HevyService {
    static let shared = HevyService()
    
    private init() {}
    
    private struct HevyWorkoutsResponse: Decodable {
        let workouts: [HevyWorkout]?
    }
    
    private struct HevyWorkout: Decodable {
        let id: String?
        let title: String?
        let start_time: String?
        let end_time: String?
        let exercises: [HevyExercise]?
    }
    
    private struct HevyExercise: Decodable {
        let title: String?
        let sets: [HevySet]?
    }
    
    private struct HevySet: Decodable {
        let weight_kg: Double?
        let reps: Int?
    }
    
    func fetchTodayWorkout() async -> TodayWorkoutSummary? {
        guard let apiKey = KeychainHelper.shared.read(account: "hevyApiKey"),
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        guard let url = URL(string: "https://api.hevyapp.com/v1/workouts?page=1&pageSize=5") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(HevyWorkoutsResponse.self, from: data)
            
            guard let workouts = decoded.workouts, !workouts.isEmpty else {
                return nil
            }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let standardIsoFormatter = ISO8601DateFormatter()
            standardIsoFormatter.formatOptions = [.withInternetDateTime]
            
            // Buscar el primer entreno que corresponda a HOY
            for workout in workouts {
                var workoutDate: Date?
                
                if let startTimeStr = workout.start_time {
                    workoutDate = isoFormatter.date(from: startTimeStr) ?? standardIsoFormatter.date(from: startTimeStr)
                }
                if workoutDate == nil, let endTimeStr = workout.end_time {
                    workoutDate = isoFormatter.date(from: endTimeStr) ?? standardIsoFormatter.date(from: endTimeStr)
                }
                
                if let date = workoutDate, Calendar.current.isDateInToday(date) {
                    var totalVolume: Double = 0
                    if let exercises = workout.exercises {
                        for exercise in exercises {
                            if let sets = exercise.sets {
                                for set in sets {
                                    let weight = set.weight_kg ?? 0
                                    let reps = Double(set.reps ?? 0)
                                    totalVolume += weight * reps
                                }
                            }
                        }
                    }
                    
                    let title = (workout.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                        ? (workout.title ?? "Entrenamiento")
                        : "Entrenamiento"
                    
                    return TodayWorkoutSummary(title: title, totalVolumeKg: totalVolume)
                }
            }
            
            return nil
        } catch {
            print("Error al consultar Hevy API: \(error.localizedDescription)")
            return nil
        }
    }
}
