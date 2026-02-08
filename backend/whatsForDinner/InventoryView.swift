// InventoryView.swift
import SwiftUI

struct InventoryView: View {
    @State private var inventory: [InventoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your pantry...")
                            .foregroundStyle(.secondary)
                    }
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadInventory() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if inventory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("Your pantry is empty")
                            .font(.title3)
                            .bold()
                        Text("Start adding items to track your ingredients")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Stats
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Total Items",
                                    value: "\(inventory.count)",
                                    icon: "shippingbox.fill"
                                )
                                
                                StatCard(
                                    title: "Low Stock",
                                    value: "\(inventory.filter { $0.is_low_stock }.count)",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                            
                            // Inventory list
                            VStack(spacing: 12) {
                                ForEach(inventory) { item in
                                    InventoryItemRow(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadInventory() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadInventory()
            }
        }
    }
    
    private func loadInventory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            inventory = try await APIService.shared.getInventory()
        } catch {
            errorMessage = "Failed to load inventory. Make sure backend is running."
        }
        
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .green
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.item.name)
                    .font(.headline)
                
                if let brand = item.item.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(item.item.category.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.quantity.formatted()) \(item.unit)")
                    .font(.headline)
                
                if item.is_low_stock {
                    Text("Low Stock")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(item.is_low_stock ? .orange : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    InventoryView()
}
