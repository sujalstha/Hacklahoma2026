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
}
