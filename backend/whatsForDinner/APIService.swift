// APIService.swift
import Foundation

class APIService {
    static let shared = APIService()
    
    // Change this to your computer's local IP when testing on physical device
    // Find it with: ifconfig (Mac) or ipconfig (Windows)
    private let baseURL = "http://localhost:8000"
    
    private init() {}
    
    // MARK: - Recipe Endpoints
    
    func getDailySuggestion() async throws -> Recipe {
        let url = URL(string: "\(baseURL)/api/recipe/daily-suggestion")!
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "user-id") // Mock user
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let recipe = try JSONDecoder().decode(Recipe.self, from: data)
        return recipe
    }
    
    func acceptRecipe(_ recipe: Recipe) async throws {
        let url = URL(string: "\(baseURL)/api/recipe/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "user-id")
        
        let acceptData = AcceptRecipeRequest(
            recipe_id: recipe.recipe_id,
            name: recipe.name,
            servings: recipe.servings,
            calories_per_serving: recipe.calories_per_serving,
            protein_per_serving: recipe.protein_per_serving,
            carbs_per_serving: recipe.carbs_per_serving,
            fat_per_serving: recipe.fat_per_serving,
            ingredients: recipe.ingredients
        )
        
        request.httpBody = try JSONEncoder().encode(acceptData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
    }
    
    // MARK: - Inventory Endpoints
    
    func getInventory() async throws -> [InventoryItem] {
        let url = URL(string: "\(baseURL)/api/pantry/inventory")!
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "user-id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let items = try JSONDecoder().decode([InventoryItem].self, from: data)
        return items
    }
    
    // MARK: - Macros Endpoints
    
    func getMacrosSummary(days: Int = 7) async throws -> MacrosSummary {
        let url = URL(string: "\(baseURL)/api/pantry/dinners/macros/summary?days=\(days)")!
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "user-id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let summary = try JSONDecoder().decode(MacrosSummary.self, from: data)
        return summary
    }
    
    func getDinnerHistory(days: Int = 30) async throws -> [DinnerHistory] {
        let url = URL(string: "\(baseURL)/api/pantry/dinners?days=\(days)")!
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "user-id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let history = try JSONDecoder().decode([DinnerHistory].self, from: data)
        return history
    }
}

// MARK: - Models

struct Recipe: Codable, Identifiable {
    var id: String { recipe_id }
    let recipe_id: String
    let name: String
    let servings: Int
    let ready_in_minutes: Int
    let image_url: String?
    let calories_per_serving: Double
    let protein_per_serving: Double
    let carbs_per_serving: Double
    let fat_per_serving: Double
    let ingredients: [Ingredient]
    let steps: [String]
    let source: String
    let spoonacular_url: String?
}

struct Ingredient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

struct AcceptRecipeRequest: Codable {
    let recipe_id: String
    let name: String
    let servings: Int
    let calories_per_serving: Double
    let protein_per_serving: Double
    let carbs_per_serving: Double
    let fat_per_serving: Double
    let ingredients: [Ingredient]
}

struct InventoryItem: Codable, Identifiable {
    let id: Int
    let item: PantryItem
    let quantity: Double
    let unit: String
    let is_low_stock: Bool
    let location: String?
}

struct PantryItem: Codable {
    let id: Int
    let name: String
    let category: String
    let brand: String?
}

struct MacrosSummary: Codable {
    let total_meals: Int
    let avg_calories: Double
    let avg_protein: Double
    let avg_carbs: Double
    let avg_fat: Double
    let date_range: String
}

struct DinnerHistory: Codable, Identifiable {
    let id: Int
    let meal_name: String
    let date_cooked: String
    let servings: Int
    let calories_per_serving: Double?
    let protein_per_serving: Double?
    let carbs_per_serving: Double?
    let fat_per_serving: Double?
    let rating: Int?
}

enum APIError: Error {
    case requestFailed
    case invalidResponse
    case decodingFailed
    
    var localizedDescription: String {
        switch self {
        case .requestFailed:
            return "Request failed. Check your connection."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingFailed:
            return "Failed to decode response."
        }
    }
}
