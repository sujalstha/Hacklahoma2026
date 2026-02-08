//
//  InventoryView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

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
