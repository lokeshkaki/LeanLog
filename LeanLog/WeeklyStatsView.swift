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
        
        // Group entries by day to get unique days with food logged
        let daysWithEntries = Set(weekEntries.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        
        let daysCount = max(1, daysWithEntries.count) // Avoid division by zero
        
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
        VStack(spacing: 16) {
            Text("Weekly Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Average calories and protein
                HStack(spacing: 12) {
                    StatCard(
                        title: "Daily Avg",
                        value: "\(weeklyAverages.avgCalories)",
                        color: AppTheme.calories,
                        unit: "kcal",
                        icon: AppTheme.macroIcon(for: .calories)
                    )
                    
                    StatCard(
                        title: "Daily Avg",
                        value: String(format: "%.1f", weeklyAverages.avgProtein),
                        color: AppTheme.protein,
                        unit: "g",
                        icon: AppTheme.macroIcon(for: .protein)
                    )
                }
                
                // Average carbs and fat
                HStack(spacing: 12) {
                    StatCard(
                        title: "Daily Avg",
                        value: String(format: "%.1f", weeklyAverages.avgCarbs),
                        color: AppTheme.carbs,
                        unit: "g",
                        icon: AppTheme.macroIcon(for: .carbs)
                    )
                    
                    StatCard(
                        title: "Daily Avg",
                        value: String(format: "%.1f", weeklyAverages.avgFat),
                        color: AppTheme.fat,
                        unit: "g",
                        icon: AppTheme.macroIcon(for: .fat)
                    )
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(unit)
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
