import Foundation
import SwiftUI
import Combine       // ← ADD THIS LINE!

class InventoryManager: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let pantryService = PantryService()
    private let userDefaultsKey = "saved_inventory_items"
    
    init() {
        // Load local first for speed, then sync with backend
        loadLocalItems()
        Task {
            await syncWithBackend()
        }
    }
    
    // MARK: - Add Item from Barcode
    
    @MainActor
    func addItem(from barcode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Check backend first for seamless integration
            let scanResult = try await pantryService.scanBarcode(barcode)
            
            if scanResult.found, let backendItem = scanResult.item {
                // Item exists on backend, just add it to user's inventory
                try await pantryService.addToInventory(itemId: backendItem.id, quantity: 1.0, unit: "piece")
                await syncWithBackend() // Refresh from backend
            } else {
                // Fallback to OpenFoodFacts for new items
                let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode)
                let newItem = InventoryItem(from: product)
                
                if items.contains(where: { $0.barcode == barcode }) {
                    errorMessage = "Item already in inventory"
                } else {
                    items.insert(newItem, at: 0)
                    saveLocalItems()
                    // TODO: In a production app, we'd also call create_pantry_item here
                }
            }
        } catch {
            errorMessage = "Failed to sync: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - CRUD Operations
    
    func removeItem(_ item: InventoryItem) {
        items.removeAll { $0.id == item.id }
        saveLocalItems()
    }
    
    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveLocalItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveLocalItems()
    }
    
    // MARK: - Persistence & Sync
    
    @MainActor
    func syncWithBackend() async {
        do {
            let backendItems = try await pantryService.fetchInventory()
            if !backendItems.isEmpty {
                // Merge or replace. For now, let's prioritize backend for preloaded items
                // but keep any locally scanned items not in backend
                var currentBarcodes = Set(items.map { $0.barcode })
                let newBackendItems = backendItems.filter { !currentBarcodes.contains($0.barcode) }
                
                if !newBackendItems.isEmpty {
                    items.append(contentsOf: newBackendItems)
                    saveLocalItems()
                }
            }
        } catch {
            print("Failed to sync with backend: \(error.localizedDescription)")
            // If local is also empty, show demo data or error
            if items.isEmpty {
                errorMessage = "Backend offline. Using local data."
            }
        }
    }
    
    private func saveLocalItems() {
        guard let encoded = try? JSONEncoder().encode(items) else {
            print("Failed to encode inventory items")
            return
        }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
    
    private func loadLocalItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([InventoryItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }
}
