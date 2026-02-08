import SwiftUI

struct MainTabView: View {
    @StateObject private var inventoryManager = InventoryManager()
    
    var body: some View {
        TabView {
            RecipesHomeView(inventoryManager: inventoryManager)
                .tabItem { Label("Recipes", systemImage: "fork.knife") }

            InventoryView(inventoryManager: inventoryManager)
                .tabItem { Label("Inventory", systemImage: "shippingbox") }

            MacrosView()
                .tabItem { Label("Macros", systemImage: "chart.bar") }
        }
    }
}
