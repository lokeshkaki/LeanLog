//
//  MacroGoalsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct MacroGoalsView: View {
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let calorieGoal: Int
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Calories Progress
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: AppTheme.macroIcon(for: .calories))
                            .foregroundStyle(AppTheme.calories)
                            .font(.headline)
                        Text("Calories")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Text("\(totalCalories) / \(calorieGoal)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.secondary)
                }
                
                ProgressView(value: Double(totalCalories), total: Double(calorieGoal))
                    .progressViewStyle(LinearProgressViewStyle(
                        tint: AppTheme.caloriesProgressColor(
                            for: totalCalories,
                            goal: calorieGoal
                        )
                    ))
                
                HStack {
                    Text("Remaining: \(max(0, calorieGoal - totalCalories)) kcal")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    Spacer()
                    if totalCalories > calorieGoal {
                        Text("Over by \(totalCalories - calorieGoal) kcal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.progressOver)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            
            // Macros Progress
            HStack(spacing: 12) {
                MacroProgressCard(
                    title: "Protein",
                    current: totalProtein,
                    goal: proteinGoal,
                    unit: "g",
                    macro: .protein
                )
                
                MacroProgressCard(
                    title: "Carbs",
                    current: totalCarbs,
                    goal: carbGoal,
                    unit: "g",
                    macro: .carbs
                )
                
                MacroProgressCard(
                    title: "Fat",
                    current: totalFat,
                    goal: fatGoal,
                    unit: "g",
                    macro: .fat
                )
            }
        }
    }
}

struct MacroProgressCard: View {
    let title: String
    let current: Double
    let goal: Double
    let unit: String
    let macro: MacroType
    
    private var baseColor: Color {
        AppTheme.macroColor(for: macro)
    }
    
    private var progressColor: Color {
        AppTheme.macroProgressColor(for: current, goal: goal, baseColor: baseColor)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: AppTheme.macroIcon(for: macro))
                .font(.caption)
                .foregroundStyle(baseColor)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondary)
            
            VStack(spacing: 4) {
                Text(String(format: "%.1f", current))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(baseColor)
                
                Text("/ \(String(format: "%.0f", goal))")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiary)
            }
            
            ProgressView(value: current, total: goal)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 0.8)
            
            Text("\(String(format: "%.0f", max(0, goal - current)))\(unit) left")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}
