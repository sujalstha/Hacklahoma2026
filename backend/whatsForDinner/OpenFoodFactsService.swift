import Foundation

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product/"
    
    private init() {}
    
    func fetchProduct(barcode: String) async throws -> FoodProduct {
        let urlString = "\(baseURL)\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenFoodFactsError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        
        guard apiResponse.status == 1, let product = apiResponse.product else {
            throw OpenFoodFactsError.productNotFound
        }
        
        return product
    }
}


// MARK: - Errors

enum OpenFoodFactsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case productNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .productNotFound:
            return "Product not found in database"
        case .decodingError:
            return "Failed to decode product data"
        }
    }
}
