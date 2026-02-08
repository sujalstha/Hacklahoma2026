//
//  ScanPlaceholderView.swift
//  whatsForDinner
//
//  Created by Sujal Shrestha on 2/7/26.
//

import SwiftUI

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

