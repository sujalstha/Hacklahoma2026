//
//  RecipeDetailView.swift
//  whatsForDinner
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var isLogging = false
    @State private var loggedMessage: String?
    @State private var logError: String?

    private let recipeService = RecipeService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerImage
                meta
                grubButton
                macros
                ingredientsSection
                stepsSection
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var headerImage: some View {
        Group {
            if let urlString = recipe.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.thinMaterial)
            .frame(height: 200)
            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary))
    }

    private var meta: some View {
        HStack(spacing: 16) {
            Label("\(recipe.readyInMinutes) min", systemImage: "clock")
            Label("\(recipe.servings) servings", systemImage: "person.2")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var grubButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let msg = loggedMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            if let err = logError {
                Text(err)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            Button {
                Task { await logRecipeForToday() }
            } label: {
                HStack(spacing: 8) {
                    if isLogging {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLogging ? "Logging…" : "I will eat this")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLogging || loggedMessage != nil)
        }
    }

    private func logRecipeForToday() async {
        isLogging = true
        logError = nil
        loggedMessage = nil
        defer { isLogging = false }
        do {
            try await recipeService.acceptRecipe(recipe)
            loggedMessage = "Logged for today! Check Macros."
        } catch {
            logError = error.localizedDescription
        }
    }

    private var macros: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per serving")
                .font(.headline)
            HStack(spacing: 20) {
                macroItem(value: Int(recipe.caloriesPerServing), unit: "cal")
                macroItem(value: Int(recipe.proteinPerServing), unit: "g protein")
                macroItem(value: Int(recipe.carbsPerServing), unit: "g carbs")
                macroItem(value: Int(recipe.fatPerServing), unit: "g fat")
            }
            .font(.subheadline)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func macroItem(value: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
            ForEach(recipe.ingredients) { ing in
                HStack {
                    Text(ing.name)
                    Spacer()
                    Text("\(formatAmount(ing.amount)) \(ing.unit ?? "")")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.headline)
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, alignment: .leading)
                    Text(step)
                        .font(.subheadline)
                }
            }
        }
    }

    private func formatAmount(_ n: Double) -> String {
        if n == Double(Int(n)) { return "\(Int(n))" }
        return String(format: "%.1f", n)
    }
}
