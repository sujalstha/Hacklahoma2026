//
//  RecipesHomeView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

struct RecipesHomeView: View {
    @ObservedObject var inventoryManager: InventoryManager
    
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case quick = "Quick"
        case highProtein = "High Protein"
        case vegetarian = "Vegetarian"
        var id: String { rawValue }
    }

    @State private var selectedFilter: Filter = .all
    @State private var showScanSheet = false
    @State private var searchText = ""
    @State private var scannedBarcode: String?

    private let recipes: [Recipe] = [
        .init(title: "Chicken Bowl"),
        .init(title: "Veggie Pasta"),
        .init(title: "Tacos"),
        .init(title: "Salmon + Rice"),
        .init(title: "Stir Fry"),
        .init(title: "Greek Salad")
    ]

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
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
                }

                HStack(spacing: 10) {
                    Menu {
                        ForEach(Filter.allCases) { f in
                            Button(f.rawValue) { selectedFilter = f }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedFilter.rawValue)
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

                ScrollView {
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(recipes) { r in
                            RecipeCard(recipe: r)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScanSheet) {
                BarcodeScannerView(scannedCode: $scannedBarcode)
            }
            .onChange(of: scannedBarcode) { oldValue, newValue in
                if let barcode = newValue {
                    Task {
                        await inventoryManager.addItem(from: barcode)
                        scannedBarcode = nil
                    }
                }
            }
        }
    }
}
