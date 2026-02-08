//
//  MacrosView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

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
