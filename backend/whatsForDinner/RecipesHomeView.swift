//
//  RecipesHomeView.swift
//  whatsForDinner
//

import SwiftUI

/// Allergy filter options for recipe suggestions (backend: egg, milk, peanut).
enum AllergyFilter: String, CaseIterable, Identifiable {
    case eggs = "Egg"
    case milk = "Milk"
    case peanuts = "Peanuts"
    case shellfish = "Shellfish"
    var id: String { rawValue }
    
    var apiValue: String {
        switch self {
        case .eggs: return "egg"
        case .milk: return "milk"
        case .peanuts: return "peanut"
        case .shellfish: return "shellfish"
        }
    }
}

struct RecipesHomeView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @State private var selectedAllergies: Set<AllergyFilter> = []
    @State private var showScanSheet = false
    @State private var scannedBarcode: String?

    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let recipeService = RecipeService()
    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                header
                allergyCheckboxes
                content
            }
            .padding()
            .lightBackgroundStyle()
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScanSheet) {
                BarcodeScannerView(scannedCode: $scannedBarcode)
            }
            .onChange(of: scannedBarcode) { _, newValue in
                if let barcode = newValue {
                    Task {
                        await inventoryManager.addItem(from: barcode)
                        scannedBarcode = nil
                    }
                }
            }
            .task { 
                if recipes.isEmpty {
                    await loadSuggestions() 
                }
            }
            .refreshable { await loadSuggestions() }
            .onChange(of: selectedAllergies) { _, _ in Task { await loadSuggestions() } }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    showScanSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.secondaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .appSecondary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
                
                Button {
                    Task { await loadSuggestions() }
                } label: {
                    Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .disabled(isLoading)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
            }
            
            Text("What's for Dinner")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appPrimary, .appSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var allergyCheckboxes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allergies")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.red) // High-visibility requirement
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AllergyFilter.allCases) { allergy in
                    Button {
                        if selectedAllergies.contains(allergy) {
                            selectedAllergies.remove(allergy)
                        } else {
                            selectedAllergies.insert(allergy)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selectedAllergies.contains(allergy) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18, weight: .semibold))
                            Text(allergy.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(selectedAllergies.contains(allergy) ? .white : Color.appPrimary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(selectedAllergies.contains(allergy) ? Color.appPrimary : Color.appPrimaryLight.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(.spring(response: 0.3), value: selectedAllergies.contains(allergy))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && recipes.isEmpty {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color.appPrimary)
                VStack(spacing: 8) {
                    Text("Securing your ingredients…")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                    Text("Cross-referencing live inventory for 100% accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let msg = errorMessage, recipes.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await loadSuggestions() } }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(filteredRecipes) { r in
                        NavigationLink {
                            RecipeDetailView(recipe: r)
                        } label: {
                            RecipeCard(recipe: r)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    private var filteredRecipes: [Recipe] {
        recipes
    }

    private func loadSuggestions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let allergens = selectedAllergies.map { $0.apiValue }
        do {
            recipes = try await recipeService.fetchSuggestions(count: 4, allergens: allergens)
        } catch {
            errorMessage = error.localizedDescription
            recipes = []
        }
    }
}
