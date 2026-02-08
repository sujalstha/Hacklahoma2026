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
        HStack(spacing: 12) {
            Button {
                showScanSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scan")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text("What's for Dinner")
                .font(.largeTitle).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await loadSuggestions() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3.weight(.semibold))
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
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
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            TextField("Search", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
