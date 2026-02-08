//
//  PantryService.swift
//  whatsForDinner
//
//  Dinners and macro summary for today (Macros tab).
//

import Foundation

struct DinnerEntry: Codable, Identifiable {
    let id: Int
    let mealName: String
    let recipeId: String?
    let servings: Int
    let caloriesPerServing: Double?
    let proteinPerServing: Double?
    let carbsPerServing: Double?
    let fatPerServing: Double?
    let dateCooked: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mealName = "meal_name"
        case recipeId = "recipe_id"
        case servings
        case caloriesPerServing = "calories_per_serving"
        case proteinPerServing = "protein_per_serving"
        case carbsPerServing = "carbs_per_serving"
        case fatPerServing = "fat_per_serving"
        case dateCooked = "date_cooked"
    }
}

struct MacroSummary: Codable {
    let totalMeals: Int
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let dateRange: String

    enum CodingKeys: String, CodingKey {
        case totalMeals = "total_meals"
        case avgCalories = "avg_calories"
        case avgProtein = "avg_protein"
        case avgCarbs = "avg_carbs"
        case avgFat = "avg_fat"
        case dateRange = "date_range"
    }
}

final class PantryService {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Dinners for the last N days (use days=1 for today).
    func fetchDinners(days: Int = 1) async throws -> [DinnerEntry] {
        guard let url = URL(string: "\(baseURL)/api/pantry/dinners?days=\(days)") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode([DinnerEntry].self, from: data)
    }

    /// Macro summary for the last N days (use days=1 for today).
    func fetchMacroSummary(days: Int = 1) async throws -> MacroSummary {
        guard let url = URL(string: "\(baseURL)/api/pantry/dinners/macros/summary?days=\(days)") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode(MacroSummary.self, from: data)
    }

    /// Fetch current user's inventory.
    func fetchInventory() async throws -> [InventoryItem] {
        guard let url = URL(string: "\(baseURL)/api/pantry/inventory") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let backendItems = try decoder.decode([BackendInventoryResponse].self, from: data)
        return backendItems.map { $0.toInventoryItem() }
    }

    /// Fetch user's macro goals.
    func fetchPreferences() async throws -> MacroGoals {
        guard let url = URL(string: "\(baseURL)/api/pantry/preferences") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MacroGoals.self, from: data)
    }

    func deleteDinner(withId dinnerId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/api/pantry/dinners/\(dinnerId)") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
    }

    /// Scan a barcode and return existing item or info.
    func scanBarcode(_ barcode: String) async throws -> BackendBarcodeResponse {
        guard let url = URL(string: "\(baseURL)/api/pantry/scan") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = ["barcode": barcode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
        return try JSONDecoder().decode(BackendBarcodeResponse.self, from: data)
    }

    /// Add a new item to the user's inventory.
    func addToInventory(itemId: Int, quantity: Double, unit: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/pantry/inventory") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "item_id": itemId,
            "quantity": quantity,
            "unit": unit,
            "location": "pantry"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeServiceError.invalidResponse
        }
    }
}

struct BackendBarcodeResponse: Codable {
    let found: Bool
    let item: BackendInventoryItem?
    let message: String
}

struct BackendInventoryItem: Codable {
    let id: Int
    let name: String
    let barcode: String?
}

// MARK: - Backend Mappings

struct MacroGoals: Codable {
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    
    enum CodingKeys: String, CodingKey {
        case calories = "target_calories"
        case protein = "target_protein"
        case carbs = "target_carbs"
        case fat = "target_fat"
    }
}

struct BackendInventoryResponse: Codable {
    let id: Int
    let itemId: Int
    let quantity: Double
    let unit: String
    let item: BackendPantryItem
    
    enum CodingKeys: String, CodingKey {
        case id, quantity, unit, item
        case itemId = "item_id"
    }
    
    func toInventoryItem() -> InventoryItem {
        InventoryItem(
            barcode: item.barcode ?? "",
            productName: item.name,
            brand: item.brand ?? "",
            imageURL: nil,
            quantity: "\(quantity) \(unit)",
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat
        )
    }
}

struct BackendPantryItem: Codable {
    let name: String
    let barcode: String?
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    
    enum CodingKeys: String, CodingKey {
        case name, barcode, brand
        case calories = "calories_per_serving"
        case protein = "protein_per_serving"
        case carbs = "carbs_per_serving"
        case fat = "fat_per_serving"
    }
}
