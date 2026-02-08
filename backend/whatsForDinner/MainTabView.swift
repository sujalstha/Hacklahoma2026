import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RecipesHomeView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }

            InventoryView()
                .tabItem { Label("Inventory", systemImage: "shippingbox") }

            MacrosView()
                .tabItem { Label("Macros", systemImage: "chart.bar") }
        }
    }
}

