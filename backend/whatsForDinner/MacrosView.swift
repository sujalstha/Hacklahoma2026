//
//  MacrosView.swift
//  whatsForDinner
//
//  Shows today's logged meals and daily macro totals (from "I will eat this").
//

import SwiftUI

struct MacrosView: View {
    @State private var dinners: [DinnerEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let pantryService = PantryService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's macros")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isLoading && dinners.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if let msg = errorMessage, dinners.isEmpty {
                    Text(msg)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    dailyTotalsCard
                    todayMealsSection
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Macros")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadToday() }
            .refreshable { await loadToday() }
        }
    }

    private var dailyTotalsCard: some View {
        let (cal, pro, carb, fat) = todayTotals()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Totals for today")
                .font(.headline)
            HStack(spacing: 24) {
                macroPill(value: Int(cal), unit: "cal", label: "Calories")
                macroPill(value: Int(pro), unit: "g", label: "Protein")
                macroPill(value: Int(carb), unit: "g", label: "Carbs")
                macroPill(value: Int(fat), unit: "g", label: "Fat")
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func macroPill(value: Int, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value) \(unit)")
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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
            dinners = try await pantryService.fetchDinners(days: 1)
        } catch {
            errorMessage = error.localizedDescription
            dinners = []
        }
    }
}
