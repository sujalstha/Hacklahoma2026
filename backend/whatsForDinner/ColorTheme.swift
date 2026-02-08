//
//  ColorTheme.swift
//  whatsForDinner
//
//  App-wide color theme with food-inspired gradients
//

import SwiftUI

extension Color {
    // Primary Colors - Fresh Green
    static let appPrimary = Color(hex: "#10b981")
    static let appPrimaryLight = Color(hex: "#d1fae5")
    static let appPrimaryDark = Color(hex: "#047857")
    
    // Secondary Colors - Warm Orange
    static let appSecondary = Color(hex: "#f97316")
    static let appSecondaryLight = Color(hex: "#ffedd5")
    static let appSecondaryDark = Color(hex: "#ea580c")
    
    // Accent Colors for Macros
    static let proteinBlue = Color(hex: "#3b82f6")
    static let carbsYellow = Color(hex: "#fbbf24")
    static let fatsOrange = Color(hex: "#f97316")
    static let caloriesRed = Color(hex: "#ef4444")
    
    // Gradient Definitions
    static let primaryGradient = LinearGradient(
        colors: [appPrimary, appPrimaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [appSecondary, appSecondaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let foodGradient = LinearGradient(
        colors: [Color(hex: "#f97316"), Color(hex: "#fb923c"), Color(hex: "#fbbf24")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Light Background Gradients
    static let lightBackground = LinearGradient(
        colors: [Color.white, Color(hex: "#f0fdf4")], // White to very light mint
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let premiumPrimaryGradient = LinearGradient(
        colors: [Color(hex: "#10b981"), Color(hex: "#059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Helper to create Color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// View Modifiers for consistent styling
extension View {
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }
    
    func premiumCardStyle() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 15, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
            )
    }

    func lightBackgroundStyle() -> some View {
        self
            .background(Color.lightBackground.ignoresSafeArea())
    }
}
