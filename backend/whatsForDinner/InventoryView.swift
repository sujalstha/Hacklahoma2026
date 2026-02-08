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
        HStack(spacing: 14) {
            // Image with gradient border
            ZStack {
                if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimaryLight, Color.appSecondaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.white.opacity(0.7))
                                .font(.title2)
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appPrimary.opacity(0.2), lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: 6) {
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
                
                // Enhanced Macros preview
                HStack(spacing: 6) {
                    if let calories = item.calories {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(Int(calories))")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.caloriesRed.gradient)
                        .clipShape(Capsule())
                    }
                    
                    if let protein = item.protein {
                        HStack(spacing: 3) {
                            Image(systemName: "p.circle.fill")
                                .font(.caption2)
                            Text("\(String(format: "%.1f", protein))g")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.proteinBlue.gradient)
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
        }
        .padding(.vertical, 8)
    }
}
