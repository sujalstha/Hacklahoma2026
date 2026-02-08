import SwiftUI

// MARK: - App Shell (Tabs)

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }

            InventoryView()
                .tabItem { Label("Inventory", systemImage: "shippingbox") }

            MacrosView()
                .tabItem { Label("Macros", systemImage: "chart.bar") }
        }
    }
}

// MARK: - Home (matches your whiteboard sketch)

struct HomeView: View {
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
                // Top row: Scan + Title
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

                // Filters row: Dropdown + Search
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

                // Recipe grid
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
                ScanPlaceholderView()
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Recipe Card UI

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

// MARK: - Scan Placeholder

struct ScanPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 44))

            Text("Scan Items")
                .font(.title2).bold()

            Text("Barcode scanning UI goes here later.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Inventory & Macros placeholders

struct InventoryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Inventory")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: 18)
                    .fill(.thinMaterial)
                    .frame(height: 120)
                    .overlay(Text("Scanned items list UI later").foregroundStyle(.secondary))

                Spacer()
            }
            .padding()
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MacrosView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Macros")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: 18)
                    .fill(.thinMaterial)
                    .frame(height: 120)
                    .overlay(Text("Macros dashboard UI later").foregroundStyle(.secondary))

                Spacer()
            }
            .padding()
            .navigationTitle("Macros")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}

