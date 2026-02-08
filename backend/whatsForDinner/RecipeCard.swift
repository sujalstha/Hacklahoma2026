//
//  RecipeCard.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

struct Recipe: Identifiable {
    let id = UUID()
    let title: String
}

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .frame(height: 110)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                )

            Text(recipe.title)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("~20m", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("• Placeholder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

