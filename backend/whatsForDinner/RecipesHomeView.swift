// RecipesHomeView.swift
import SwiftUI

struct RecipesHomeView: View {
    @State private var recipe: Recipe?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showScanSheet = false
    @State private var showAcceptAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What's for Dinner?")
                                .font(.largeTitle)
                                .bold()
                            Text("Your personalized suggestion")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Finding your perfect recipe...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 300)
                    } else if let errorMessage {
                        // Error state
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await loadRecipe() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(height: 300)
                    } else if let recipe {
                        // Recipe content
                        RecipeDetailCard(recipe: recipe)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button {
                                Task { await loadRecipe() }
                            } label: {
                                Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            Button {
                                Task { await acceptRecipe() }
                            } label: {
                                Label("Cook This!", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScanSheet = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showScanSheet) {
                ScanPlaceholderView()
                    .presentationDetents([.medium])
            }
            .alert("Success!", isPresented: $showAcceptAlert) {
                Button("OK") { }
            } message: {
                Text("Recipe accepted! Check Macros tab to see your logged meal.")
            }
            .task {
                await loadRecipe()
            }
        }
    }
    
    private func loadRecipe() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recipe = try await APIService.shared.getDailySuggestion()
        } catch {
            errorMessage = "Failed to load recipe. Make sure your backend is running on http://localhost:8000"
        }
        
        isLoading = false
    }
    
    private func acceptRecipe() async {
        guard let recipe else { return }
        
        do {
            try await APIService.shared.acceptRecipe(recipe)
            showAcceptAlert = true
        } catch {
            errorMessage = "Failed to accept recipe: \(error.localizedDescription)"
        }
    }
}

// MARK: - Recipe Detail Card

struct RecipeDetailCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipe image
            if let imageURL = recipe.image_url, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.thinMaterial)
                        .overlay(ProgressView())
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(recipe.name)
                    .font(.title2)
                    .bold()
                
                // Meta info
                HStack(spacing: 16) {
                    Label("\(recipe.ready_in_minutes) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                // Macros
                HStack(spacing: 12) {
                    MacroBox(label: "Cal", value: "\(Int(recipe.calories_per_serving))")
                    MacroBox(label: "Protein", value: "\(Int(recipe.protein_per_serving))g")
                    MacroBox(label: "Carbs", value: "\(Int(recipe.carbs_per_serving))g")
                    MacroBox(label: "Fat", value: "\(Int(recipe.fat_per_serving))g")
                }
                
                Divider()
                
                // Ingredients
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                    
                    ForEach(recipe.ingredients.indices, id: \.self) { index in
                        let ing = recipe.ingredients[index]
                        HStack {
                            Text("•")
                            Text("\(ing.amount.formatted()) \(ing.unit) \(ing.name)")
                        }
                        .font(.subheadline)
                    }
                }
                
                Divider()
                
                // Steps
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cooking Steps")
                        .font(.headline)
                    
                    ForEach(recipe.steps.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .bold()
                                .foregroundStyle(.secondary)
                            Text(recipe.steps[index])
                        }
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    }
                }
                
                // Source link
                if let urlString = recipe.spoonacular_url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("View original recipe", systemImage: "arrow.up.right.square")
                            .font(.footnote)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

struct MacroBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RecipesHomeView()
}
