import Foundation

struct OFFProductResult {
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
}

enum OFFError: Error {
    case invalidURL
    case networkError(Error)
    case notFound
    case invalidData
}

struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

struct OFFProduct: Decodable {
    let productName: String?
    let nutriments: OFFNutriments?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
    }
}

struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
    }
}

final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    private init() {}
    
    func fetchProduct(barcode: String) async throws -> OFFProductResult? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            throw OFFError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OFFError.notFound
        }
        
        do {
            let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
            if decoded.status == 1,
               let product = decoded.product,
               let name = product.productName,
               let kcal = product.nutriments?.energyKcal100g,
               let protein = product.nutriments?.proteins100g {
                return OFFProductResult(name: name, caloriesPer100g: kcal, proteinPer100g: protein)
            } else {
                return nil
            }
        } catch {
            throw OFFError.invalidData
        }
    }
}
