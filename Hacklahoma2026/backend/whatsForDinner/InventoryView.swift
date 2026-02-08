//
//  InventoryView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

struct InventoryView: View {
    @ObservedObject var inventoryManager: InventoryManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                if inventoryManager.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No Items Yet")
                            .font(.title2)
                            .bold()
                        
                        Text("Scan items from the Recipes tab to add them to your inventory")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(inventoryManager.items) { item in
                            InventoryItemRow(item: item)
                        }
                        .onDelete(perform: inventoryManager.removeItems)
                    }
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                if !inventoryManager.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                inventoryManager.clearAll()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .overlay {
                if inventoryManager.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Fetching product info...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .alert("Error", isPresented: .constant(inventoryManager.errorMessage != nil)) {
                Button("OK") {
                    inventoryManager.errorMessage = nil
                }
            } message: {
                if let error = inventoryManager.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let quantity = item.quantity {
                    Text(quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Macros preview
                HStack(spacing: 8) {
                    if let calories = item.calories {
                        Label("\(Int(calories)) kcal", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    
                    if let protein = item.protein {
                        Label("\(String(format: "%.1f", protein))g", systemImage: "p.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
