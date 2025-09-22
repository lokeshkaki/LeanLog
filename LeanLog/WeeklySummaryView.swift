//
//  WeeklySummaryView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/20/25.
//

import SwiftUI
import SwiftData
import Charts

struct WeeklyPoint: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let calories: Int
}

struct WeeklySummaryView: View {
    // Query the current week using constants passed via init
    @Query private var weekEntries: [FoodEntry]

    init(referenceDay: Date) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: referenceDay)
        // Start of week (using weekOfYear for locale-aware weeks)
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dayStart))!
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfWeek)!

        let predicate = #Predicate<FoodEntry> { $0.date >= startOfWeek && $0.date < endOfWeek }
        _weekEntries = Query(filter: predicate, sort: [SortDescriptor(\FoodEntry.date, order: .forward)])
    }

    var points: [WeeklyPoint] {
        let cal = Calendar.current
        // Sum calories per day
        let grouped = Dictionary(grouping: weekEntries) { cal.startOfDay(for: $0.date) }
        var out: [WeeklyPoint] = []
        // Build 7 bars starting from start of week
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: cal.startOfDay(for: Date())))!
        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: i, to: startOfWeek)!
            let kcal = (grouped[cal.startOfDay(for: day)] ?? []).reduce(0) { $0 + $1.calories }
            let label = DateFormatter.shortWeekday.string(from: day)
            out.append(WeeklyPoint(label: label, calories: kcal))
        }
        return out
    }
    
    private var maxCalories: Int {
        max(points.map { $0.calories }.max() ?? 0, 1000)
    }

    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Day", point.label),
                y: .value("kcal", point.calories)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        AppTheme.calories.opacity(0.9),
                        AppTheme.calories.opacity(0.6),
                        AppTheme.calories.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(8, style: .continuous)
        }
        .chartYScale(domain: 0...maxCalories)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    .foregroundStyle(.clear)
                AxisTick(stroke: StrokeStyle(lineWidth: 0))
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 6]))
                    .foregroundStyle(AppTheme.secondary.opacity(0.2))
                AxisTick(stroke: StrokeStyle(lineWidth: 0))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
            }
        }
        .chartBackground { chartProxy in
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.systemBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.secondary.opacity(0.1), lineWidth: 1)
                )
        }
        .chartPlotStyle { plotContent in
            plotContent
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.systemBackground.opacity(0.1))
                )
        }
        .frame(height: 220)
        .padding(.vertical, 8)
    }
}

private extension DateFormatter {
    static let shortWeekday: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("EE")
        return df
    }()
}
