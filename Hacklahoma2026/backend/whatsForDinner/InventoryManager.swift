import Foundation
import SwiftUI
import Combine       // ← ADD THIS LINE!

class InventoryManager: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaultsKey = "saved_inventory_items"
    
    init() {
        loadItems()
    }
    
    // MARK: - Add Item from Barcode
    
    @MainActor
    func addItem(from barcode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode)
            let newItem = InventoryItem(from: product)
            
            // Check if item already exists
            if items.contains(where: { $0.barcode == barcode }) {
                errorMessage = "Item already in inventory"
            } else {
                items.insert(newItem, at: 0) // Add to beginning
                saveItems()
            }
            
        } catch let error as OpenFoodFactsError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to fetch product: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - CRUD Operations
    
    func removeItem(_ item: InventoryItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    // MARK: - Persistence
    
    private func saveItems() {
        guard let encoded = try? JSONEncoder().encode(items) else {
            print("Failed to encode inventory items")
            return
        }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([InventoryItem].self, from: data) else {
            // Load sample data for demo purposes
            items = []
            return
        }
        items = decoded
    }
}
