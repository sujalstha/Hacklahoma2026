//
//  MacrosView.swift
//  whatsForDinner
//
//  Shows today's logged meals and daily macro totals (from "I will eat this").
//

import SwiftUI

struct MacrosView: View {
    @State private var dinners: [DinnerEntry] = []
    @State private var goals: MacroGoals?
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let pantryService = PantryService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Today's macros")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .padding(.top)
                    
                    if isLoading && dinners.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let msg = errorMessage, dinners.isEmpty {
                        Text(msg)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        parliamentChartsGrid
                        todayMealsSection
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Macros")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadToday() }
            .refreshable { await loadToday() }
        }
    }

    private var parliamentChartsGrid: some View {
        let (cal, pro, carb, fat) = todayTotals()
        return VStack(spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ParliamentChart(
                    value: cal,
                    goal: goals?.calories ?? 2000,
                    label: "Calories",
                    unit: "kcal",
                    color: .caloriesRed
                )
                ParliamentChart(
                    value: pro,
                    goal: goals?.protein ?? 150,
                    label: "Protein",
                    unit: "g",
                    color: .proteinBlue
                )
                ParliamentChart(
                    value: carb,
                    goal: goals?.carbs ?? 200,
                    label: "Carbs",
                    unit: "g",
                    color: .carbsYellow
                )
                ParliamentChart(
                    value: fat,
                    goal: goals?.fat ?? 70,
                    label: "Fat",
                    unit: "g",
                    color: .fatsOrange
                )
            }
        }
    }

    private var todayMealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meals logged today")
                .font(.headline)
            if dinners.isEmpty {
                Text("No meals yet. Tap \"I will eat this\" on a recipe to log.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(dinners) { d in
                    dinnerRow(d)
                }
            }
        }
    }

    private func dinnerRow(_ d: DinnerEntry) -> some View {
        let cal = (d.caloriesPerServing ?? 0) * Double(d.servings)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(d.mealName)
                    .font(.subheadline.weight(.medium))
                Text("\(d.servings) serving\(d.servings == 1 ? "" : "s") · \(Int(cal)) cal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func todayTotals() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        var cal: Double = 0, pro: Double = 0, carb: Double = 0, fat: Double = 0
        for d in dinners {
            let s = Double(d.servings)
            cal += (d.caloriesPerServing ?? 0) * s
            pro += (d.proteinPerServing ?? 0) * s
            carb += (d.carbsPerServing ?? 0) * s
            fat += (d.fatPerServing ?? 0) * s
        }
        return (cal, pro, carb, fat)
    }

    private func loadToday() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let dinnersTask = pantryService.fetchDinners(days: 1)
            async let goalsTask = pantryService.fetchPreferences()
            
            let (fetchedDinners, fetchedGoals) = try await (dinnersTask, goalsTask)
            self.dinners = fetchedDinners
            self.goals = fetchedGoals
        } catch {
            print("Macros load error: \(error)")
            // If goals fail, we still want to show dinners if possible
            if dinners.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Parliament Chart Component

struct ParliamentChart: View {
    let value: Double
    let goal: Double
    let label: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(color.opacity(0.1), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                Circle()
                    .trim(from: 0.5, to: 0.5 + (progress * 0.5))
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .offset(y: -10)
            }
            .frame(height: 80)
            
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
