// MacrosView.swift
import SwiftUI

struct MacrosView: View {
    @State private var summary: MacrosSummary?
    @State private var history: [DinnerHistory] = []
    @State private var isLoading = false
    @State private var selectedDays = 7
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading nutrition data...")
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
                            Task { await loadMacros() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Time selector
                            Picker("Time Range", selection: $selectedDays) {
                                Text("7 Days").tag(7)
                                Text("30 Days").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .onChange(of: selectedDays) { _, _ in
                                Task { await loadMacros() }
                            }
                            
                            // Summary card
                            if let summary {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Average Daily Macros")
                                        .font(.headline)
                                    
                                    Text(summary.date_range)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        MacroStatBox(
                                            label: "Calories",
                                            value: "\(Int(summary.avg_calories))"
                                        )
                                        MacroStatBox(
                                            label: "Protein",
                                            value: "\(Int(summary.avg_protein))g"
                                        )
                                        MacroStatBox(
                                            label: "Carbs",
                                            value: "\(Int(summary.avg_carbs))g"
                                        )
                                        MacroStatBox(
                                            label: "Fat",
                                            value: "\(Int(summary.avg_fat))g"
                                        )
                                    }
                                    
                                    Text("Based on \(summary.total_meals) meals")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }
                            
                            // Meal history
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Meals")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if history.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                        Text("No meals logged yet")
                                            .foregroundStyle(.secondary)
                                        Text("Accept a recipe to start tracking!")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                } else {
                                    ForEach(history) { meal in
                                        MealHistoryRow(meal: meal)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Macros")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadMacros() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadMacros()
            }
        }
    }
    
    private func loadMacros() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let summaryTask = APIService.shared.getMacrosSummary(days: selectedDays)
            async let historyTask = APIService.shared.getDinnerHistory(days: selectedDays)
            
            summary = try await summaryTask
            history = try await historyTask
        } catch {
            errorMessage = "Failed to load macros. Make sure backend is running."
        }
        
        isLoading = false
    }
}

struct MacroStatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MealHistoryRow: View {
    let meal: DinnerHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.meal_name)
                    .font(.headline)
                Spacer()
                Text(formatDate(meal.date_cooked))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let calories = meal.calories_per_serving,
               let protein = meal.protein_per_serving,
               let carbs = meal.carbs_per_serving,
               let fat = meal.fat_per_serving {
                
                HStack(spacing: 12) {
                    MealMacroTag(value: "\(Int(calories)) cal")
                    MealMacroTag(value: "\(Int(protein))g protein")
                    MealMacroTag(value: "\(Int(carbs))g carbs")
                    MealMacroTag(value: "\(Int(fat))g fat")
                }
            }
            
            HStack {
                Text("\(meal.servings) servings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let rating = meal.rating {
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct MealMacroTag: View {
    let value: String
    
    var body: some View {
        Text(value)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    MacrosView()
}
