//
//  FoodEntryRow.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    let timeFormatter: DateFormatter
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                topRow
                if hasNutritionInfo {
                    macroRow
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var topRow: some View {
        HStack(alignment: .top) {
            leftColumn
            Spacer()
            rightColumn
        }
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.name)
                .foregroundStyle(.primary)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            timeRow
        }
    }
    
    private var timeRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
            Text(timeFormatter.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
        }
    }
    
    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            caloriesRow
            servingSizeRow
        }
    }
    
    private var caloriesRow: some View {
        HStack(spacing: 6) {
            Image(systemName: AppTheme.macroIcon(for: .calories))
                .font(.caption)
                .foregroundStyle(AppTheme.calories)
            Text("\(entry.calories) kcal")
                .foregroundStyle(.primary)
                .fontWeight(.semibold)
                .font(.subheadline)
        }
    }
    
    @ViewBuilder
    private var servingSizeRow: some View {
        if let servingSize = entry.servingSize, servingSize > 0 {
            Text("\(String(format: "%.1f", servingSize))\(entry.servingUnit ?? "")")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var macroRow: some View {
        HStack(spacing: 8) {
            proteinText
            bulletSeparator
            carbsText
            bulletSeparator
            fatText
            Spacer()
        }
        .font(.caption)
    }
    
    private var proteinText: some View {
        Text("P \(String(format: "%.1f", entry.protein ?? 0))g")
            .foregroundStyle(AppTheme.protein)
    }
    
    private var carbsText: some View {
        Text("C \(String(format: "%.1f", entry.carbs ?? 0))g")
            .foregroundStyle(AppTheme.carbs)
    }
    
    private var fatText: some View {
        Text("F \(String(format: "%.1f", entry.fat ?? 0))g")
            .foregroundStyle(AppTheme.fat)
    }
    
    private var bulletSeparator: some View {
        Text("•").foregroundStyle(AppTheme.secondary)
    }
    
    private var hasNutritionInfo: Bool {
        let protein = entry.protein ?? 0
        let carbs = entry.carbs ?? 0
        let fat = entry.fat ?? 0
        return protein + carbs + fat > 0
    }
}
