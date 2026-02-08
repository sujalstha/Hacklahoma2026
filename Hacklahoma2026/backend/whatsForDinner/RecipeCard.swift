//
//  RecipeCard.swift
//  whatsForDinner
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipeImage
            Text(recipe.name)
                .font(.headline)
                .lineLimit(2)
            HStack(spacing: 8) {
                Label("\(recipe.readyInMinutes)m", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• \(recipe.servings) servings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var recipeImage: some View {
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.thinMaterial)
            .overlay(
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            )
    }
}
