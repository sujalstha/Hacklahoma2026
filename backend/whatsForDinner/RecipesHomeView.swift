//
//  RecipesHomeView.swift
//  whatsForDinner
//

import SwiftUI

/// Allergy filter options for recipe suggestions (backend: egg, milk, peanut).
enum AllergyFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case eggs = "Eggs"
    case milk = "Milk"
    case peanuts = "Peanuts"
    var id: String { rawValue }
    var apiValue: String? {
        switch self {
        case .all: return nil
        case .eggs: return "egg"
        case .milk: return "milk"
        case .peanuts: return "peanut"
        }
    }
}

struct RecipesHomeView: View {
    @ObservedObject var inventoryManager: InventoryManager

    @State private var selectedAllergy: AllergyFilter = .all
    @State private var showScanSheet = false
    @State private var searchText = ""
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
                filterAndSearch
                content
            }
            .padding()
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
            .task { await loadSuggestions() }
            .refreshable { await loadSuggestions() }
            .onChange(of: selectedAllergy) { _, _ in Task { await loadSuggestions() } }
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

    private var filterAndSearch: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(AllergyFilter.allCases) { f in
                    Button(f.rawValue) { selectedAllergy = f }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "allergens")
                    Text(selectedAllergy.rawValue)
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedAllergy == .all ? .primary : Color.appPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(selectedAllergy == .all ? Color(.systemBackground) : Color.appPrimaryLight)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectedAllergy == .all ? Color.gray.opacity(0.2) : Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search recipes", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && recipes.isEmpty {
            VStack(spacing: 16) {
                ProgressView()
                Text("Finding recipes…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
        var list = recipes
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private func loadSuggestions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let allergens: [String] = selectedAllergy.apiValue.map { [$0] } ?? []
        do {
            recipes = try await recipeService.fetchSuggestions(count: 4, allergens: allergens)
        } catch {
            errorMessage = error.localizedDescription
            recipes = []
        }
    }
}
