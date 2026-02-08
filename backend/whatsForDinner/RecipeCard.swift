//
//  RecipeCard.swift
//  whatsForDinner
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipeImage
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Label("\(recipe.readyInMinutes)m", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("• \(recipe.servings) servings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(isPressed ? 0.05 : 0.15), radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 2 : 6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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
                            .overlay(gradientOverlay)
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
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var gradientOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color.appPrimaryLight, Color.appSecondaryLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            )
    }
}
