//
//  RecipeService.swift
//  whatsForDinner
//
//  Networking layer for Recipe API (suggestions, daily, accept).
//

import Foundation

enum RecipeServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid server response"
        case .httpStatus(let code): return "Server error (\(code)). Is the backend running?"
        case .decoding: return "Could not read recipe data"
        }
    }
}

final class RecipeService {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Fetch recipe suggestions (recipeEngine). Optionally filter by allergens: egg, milk, peanut.
    func fetchSuggestions(count: Int = 4, allergens: [String] = []) async throws -> [Recipe] {
        var components = URLComponents(string: "\(baseURL)/api/recipe/suggestions")
        components?.queryItems = [URLQueryItem(name: "count", value: "\(count)")]
        if !allergens.isEmpty {
            components?.queryItems?.append(URLQueryItem(name: "allergens", value: allergens.joined(separator: ",")))
        }
        guard let url = components?.url else { throw RecipeServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RecipeServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw RecipeServiceError.httpStatus(http.statusCode) }

        let decoder = JSONDecoder()
        return try decoder.decode([Recipe].self, from: data)
    }

    /// Log recipe as "I will eat this" for today so it shows in Macros.
    func acceptRecipe(_ recipe: Recipe) async throws {
        guard let url = URL(string: "\(baseURL)/api/recipe/accept") else { throw RecipeServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "recipe_id": recipe.recipeId,
            "name": recipe.name,
            "servings": recipe.servings,
            "calories_per_serving": recipe.caloriesPerServing,
            "protein_per_serving": recipe.proteinPerServing,
            "carbs_per_serving": recipe.carbsPerServing,
            "fat_per_serving": recipe.fatPerServing,
            "ingredients": recipe.ingredients.map { ["name": $0.name, "amount": $0.amount, "unit": $0.unit ?? ""] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RecipeServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw RecipeServiceError.httpStatus(http.statusCode) }
    }

    /// Single daily suggestion (optional).
    func fetchDailySuggestion() async throws -> Recipe {
        guard let url = URL(string: "\(baseURL)/api/recipe/daily-suggestion") else {
            throw RecipeServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RecipeServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw RecipeServiceError.httpStatus(http.statusCode) }

        let decoder = JSONDecoder()
        return try decoder.decode(Recipe.self, from: data)
    }
}
