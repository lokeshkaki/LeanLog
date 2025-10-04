//
//  WeeklyView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Modern, insightful weekly progress tracking - FIXED
//

import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query(sort: [SortDescriptor(\FoodEntry.date, order: .forward)])
    private var allEntries: [FoodEntry]
    
    @State private var selectedWeekStart = Calendar.current.startOfDay(for: .now)
    
    private static let shortDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.calendar = .current
        df.dateFormat = "MMM d"
        return df
    }()
    
    private var weekRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: selectedWeekStart)?.start ?? selectedWeekStart
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        return (cal.startOfDay(for: start), cal.startOfDay(for: end))
    }
    
    private var weekEntries: [FoodEntry] {
        let cal = Calendar.current
        let startOfWeek = cal.startOfDay(for: weekRange.start)
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return allEntries.filter { entry in
            entry.date >= startOfWeek && entry.date < endOfWeek
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Week Navigation
                    WeekNavigationHeader(
                        weekRange: weekRange,
                        onPrevious: { changeWeek(by: -1) },
                        onNext: { changeWeek(by: 1) }
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.md)
                    
                    if weekEntries.isEmpty {
                        EmptyWeekView()
                            .padding(.top, 60)
                    } else {
                        // Weekly Stats Overview
                        WeeklyStatsOverview(weekEntries: weekEntries)
                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                        
                        // Daily Breakdown Chart
                        DailyBreakdownChart(weekEntries: weekEntries, weekStart: weekRange.start)
                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                        
                        // Insights & Highlights
                        WeeklyInsights(weekEntries: weekEntries)
                            .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Progress")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
            }
        }
    }
    
    private func changeWeek(by weeks: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedWeekStart) ?? selectedWeekStart
            selectedWeekStart = Calendar.current.startOfDay(for: selectedWeekStart)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Week Navigation Header
struct WeekNavigationHeader: View {
    let weekRange: (start: Date, end: Date)
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    private static let shortDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.surface)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Self.shortDayFormatter.string(from: weekRange.start)) – \(Self.shortDayFormatter.string(from: weekRange.end))")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                
                if isCurrentWeek {
                    Text("This Week")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                }
            }
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.surface)
                    .clipShape(Circle())
            }
        }
    }
    
    private var isCurrentWeek: Bool {
        let cal = Calendar.current
        let currentWeekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return cal.isDate(weekRange.start, equalTo: currentWeekStart, toGranularity: .day)
    }
}

// MARK: - Empty Week View
struct EmptyWeekView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.labelTertiary)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No Data This Week")
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                
                Text("Start logging meals to see your progress")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.screenPadding)
    }
}

// MARK: - Weekly Stats Overview
struct WeeklyStatsOverview: View {
    let weekEntries: [FoodEntry]
    
    @AppStorage("dailyCalorieGoal") private var calorieGoal = 2000
    @AppStorage("proteinGoal") private var proteinGoal = 100.0
    @AppStorage("carbGoal") private var carbGoal = 250.0
    @AppStorage("fatGoal") private var fatGoal = 70.0
    
    private var weeklyAverages: (calories: Int, protein: Double, carbs: Double, fat: Double) {
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
    
    private var activeDaysCount: Int {
        Set(weekEntries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Weekly Overview")
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.accent)
                    Text("\(activeDaysCount)/7 days")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.accent)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.accent.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Macro Cards Grid
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ModernStatCard(
                        icon: AppTheme.Icons.calories,
                        title: "Calories",
                        value: "\(weeklyAverages.calories)",
                        unit: "kcal",
                        goal: Double(calorieGoal), // FIXED: Convert Int to Double
                        actual: Double(weeklyAverages.calories),
                        color: AppTheme.Colors.calories
                    )
                    
                    ModernStatCard(
                        icon: AppTheme.Icons.protein,
                        title: "Protein",
                        value: String(format: "%.0f", weeklyAverages.protein),
                        unit: "g",
                        goal: proteinGoal,
                        actual: weeklyAverages.protein,
                        color: AppTheme.Colors.protein
                    )
                }
                
                HStack(spacing: AppTheme.Spacing.md) {
                    ModernStatCard(
                        icon: AppTheme.Icons.carbs,
                        title: "Carbs",
                        value: String(format: "%.0f", weeklyAverages.carbs),
                        unit: "g",
                        goal: carbGoal,
                        actual: weeklyAverages.carbs,
                        color: AppTheme.Colors.carbs
                    )
                    
                    ModernStatCard(
                        icon: AppTheme.Icons.fat,
                        title: "Fat",
                        value: String(format: "%.0f", weeklyAverages.fat),
                        unit: "g",
                        goal: fatGoal,
                        actual: weeklyAverages.fat,
                        color: AppTheme.Colors.fat
                    )
                }
            }
        }
    }
}

// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let goal: Double
    let actual: Double
    let color: Color
    
    private var percentage: Double {
        guard goal > 0 else { return 0 }
        return (actual / goal) * 100
    }
    
    private var trendIcon: String {
        if percentage >= 95 && percentage <= 105 {
            return "checkmark.circle.fill"
        } else if percentage > 105 {
            return "arrow.up.circle.fill"
        } else {
            return "arrow.down.circle.fill"
        }
    }
    
    private var trendColor: Color {
        if percentage >= 95 && percentage <= 105 {
            return AppTheme.Colors.success
        } else if percentage > 105 {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.labelTertiary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundStyle(trendColor)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(color)
                
                Text(unit)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
            }
            
            Text("Daily Avg")
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.labelTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

// MARK: - Daily Breakdown Chart (REDESIGNED - Clean & Consistent)
struct DailyBreakdownChart: View {
    let weekEntries: [FoodEntry]
    let weekStart: Date
    
    @AppStorage("dailyCalorieGoal") private var calorieGoal = 2000
    
    private var dailyData: [(day: String, calories: Int, date: Date, hasData: Bool)] {
        let cal = Calendar.current
        var results: [(String, Int, Date, Bool)] = []
        
        for dayOffset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let startOfDay = cal.startOfDay(for: date)
            
            let dayEntries = weekEntries.filter { cal.isDate($0.date, inSameDayAs: startOfDay) }
            let totalCalories = dayEntries.reduce(0) { $0 + $1.calories }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayName = formatter.string(from: date)
            let shortDay = String(dayName.prefix(1)) // S, M, T, W, T, F, S
            
            results.append((shortDay, totalCalories, startOfDay, !dayEntries.isEmpty))
        }
        
        return results
    }
    
    private var maxCalories: Int {
        // Use goal as max height reference for consistent visual scale
        let dataMax = dailyData.map(\.calories).max() ?? 0
        return max(dataMax, calorieGoal)
    }
    
    private var activeDays: Int {
        dailyData.filter(\.hasData).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Daily Breakdown")
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                
                Spacer()
                
                // Active days badge
                Text("\(activeDays)/7")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 12) {
                // Chart - Clean bars with consistent heights
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(dailyData, id: \.date) { item in
                        VStack(spacing: 8) {
                            // Bar with consistent scaling
                            let heightRatio = maxCalories > 0 ? CGFloat(item.calories) / CGFloat(maxCalories) : 0
                            let barHeight = max(8, heightRatio * 110) // Consistent max height 110pt
                            let isToday = Calendar.current.isDateInToday(item.date)
                            let isOverGoal = item.calories > calorieGoal && item.hasData
                            
                            VStack(spacing: 0) {
                                // Value label (only if has data)
                                if item.hasData {
                                    Text("\(item.calories)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                                        .frame(height: 16)
                                } else {
                                    Color.clear.frame(height: 16)
                                }
                                
                                // Bar
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        item.hasData ?
                                        (isOverGoal ? AppTheme.Colors.warning : AppTheme.Colors.accent)
                                        : AppTheme.Colors.stroke
                                    )
                                    .frame(height: barHeight)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 126) // Fixed total height = 16 (label) + 110 (max bar)
                            
                            // Day label
                            Text(item.day)
                                .font(.system(size: 13, weight: isToday ? .bold : .semibold))
                                .foregroundStyle(isToday ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                        }
                    }
                }
                
                Divider()
                    .overlay(AppTheme.Colors.stroke)
                
                // Legend + Goal (one line, no wrapping)
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // On Track
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 8, height: 8)
                            Text("On Track")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                        
                        // Over Goal
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.Colors.warning)
                                .frame(width: 8, height: 8)
                            Text("Over")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                    }
                    
                    // Goal on separate line
                    HStack {
                        Image(systemName: "scope")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                        Text("Daily Goal: \(calorieGoal) kcal")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }
}

// MARK: - Weekly Insights (FIXED - Smart abbreviation, no cutoff)
struct WeeklyInsights: View {
    let weekEntries: [FoodEntry]
    
    private var bestDay: (date: Date, calories: Int)? {
        let cal = Calendar.current
        let dailyTotals = Dictionary(grouping: weekEntries, by: { cal.startOfDay(for: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.calories } }
        
        guard let best = dailyTotals.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
    
    private var consistencyScore: Int {
        let activeDays = Set(weekEntries.map { Calendar.current.startOfDay(for: $0.date) }).count
        return Int((Double(activeDays) / 7.0) * 100)
    }
    
    // Use short day format (Mon, Tue, etc.) to prevent cutoff
    private var bestDayString: String {
        guard let best = bestDay else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Short format: Mon, Tue, Wed, etc.
        return formatter.string(from: best.date)
    }
    
    private var bestDayCalories: Int {
        bestDay?.calories ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Insights")
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                // Consistency
                InsightRow(
                    icon: "flame.fill",
                    title: "Consistency",
                    value: "\(consistencyScore)%",
                    color: consistencyScore >= 70 ? AppTheme.Colors.success : AppTheme.Colors.warning
                )
                
                // Best Day - FIXED: Use short day format
                if bestDay != nil {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "star.fill")
                            .font(.body)
                            .foregroundStyle(AppTheme.Colors.accent)
                            .frame(width: 24)
                        
                        Text("Best Day")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Text(bestDayString)
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                            
                            Text("•")
                                .foregroundStyle(AppTheme.Colors.labelTertiary)
                            
                            Text("\(bestDayCalories) kcal")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Total Entries
                InsightRow(
                    icon: "list.bullet.clipboard",
                    title: "Total Entries",
                    value: "\(weekEntries.count) meals",
                    color: AppTheme.Colors.labelPrimary
                )
            }
            .padding()
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WeeklyView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
