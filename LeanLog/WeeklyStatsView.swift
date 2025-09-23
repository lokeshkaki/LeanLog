//
//  WeeklyStatsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData

struct WeeklyStatsView: View {
    let weekStart: Date
    // Remove @Binding since we don't need macro selection anymore
    
    @Query(sort: [SortDescriptor(\FoodEntry.date, order: .forward)])
    private var allEntries: [FoodEntry]
    
    private var weekEntries: [FoodEntry] {
        let cal = Calendar.current
        let startOfWeek = cal.startOfDay(for: weekStart)
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return allEntries.filter { entry in
            entry.date >= startOfWeek && entry.date < endOfWeek
        }
    }
    
    private var weeklyAverages: (avgCalories: Int, avgProtein: Double, avgCarbs: Double, avgFat: Double) {
        guard !weekEntries.isEmpty else { return (0, 0, 0, 0) }
        
        let daysWithEntries = Set(weekEntries.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        
        let daysCount = max(1, daysWithEntries.count)
        
        let totalCalories = weekEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = weekEntries.reduce(0) { $0 + ($1.protein ?? 0) }
        let totalCarbs = weekEntries.reduce(0) { $0 + ($1.carbs ?? 0) }
        let totalFat = weekEntries.reduce(0) { $0 + ($1.fat ?? 0) }
        
        return (
            totalCalories / daysCount,
            totalProtein / Double(daysCount),
            totalCarbs / Double(daysCount),
            totalFat / Double(daysCount)
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    macroType: .calories,
                    value: "\(weeklyAverages.avgCalories)"
                )
                
                StatCard(
                    macroType: .protein,
                    value: String(format: "%.1f", weeklyAverages.avgProtein)
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    macroType: .carbs,
                    value: String(format: "%.1f", weeklyAverages.avgCarbs)
                )
                
                StatCard(
                    macroType: .fat,
                    value: String(format: "%.1f", weeklyAverages.avgFat)
                )
            }
        }
    }
}

// Simple non-interactive stat card
struct StatCard: View {
    let macroType: MacroType
    let value: String
    
    private var macroUnit: String {
        switch macroType {
        case .calories: return "kcal"
        case .protein, .carbs, .fat: return "g"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: AppTheme.macroIcon(for: macroType))
                .font(.title3)
                .foregroundStyle(AppTheme.macroColor(for: macroType))
            
            Text("Daily Avg")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.macroColor(for: macroType))
                
                Text(macroUnit)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}
