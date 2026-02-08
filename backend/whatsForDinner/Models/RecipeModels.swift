//
//  RecipeModels.swift
//  whatsForDinner
//
//  Data models for Recipe API (matches backend /api/recipe/suggestions).
//

import Foundation

// MARK: - API Recipe (from backend)

struct RecipeIngredient: Codable, Identifiable {
    var id: String { "\(name)-\(amount)" }
    let name: String
    let amount: Double
    let unit: String?

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case unit
    }
}

struct Recipe: Codable, Identifiable {
    let recipeId: String
    let name: String
    let servings: Int
    let readyInMinutes: Int
    let imageUrl: String?
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let source: String
    let spoonacularUrl: String?

    var id: String { recipeId }

    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case name
        case servings
        case readyInMinutes = "ready_in_minutes"
        case imageUrl = "image_url"
        case caloriesPerServing = "calories_per_serving"
        case proteinPerServing = "protein_per_serving"
        case carbsPerServing = "carbs_per_serving"
        case fatPerServing = "fat_per_serving"
        case ingredients
        case steps
        case source
        case spoonacularUrl = "spoonacular_url"
    }
}
