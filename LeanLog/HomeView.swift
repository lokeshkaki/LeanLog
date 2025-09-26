//
//  HomeView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Stable ForEach using Identifiable items, tiny row container, fixed string interpolation
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    // Goals
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000
    @AppStorage("proteinGoal") private var proteinGoal = 100.0
    @AppStorage("carbGoal") private var carbGoal = 250.0
    @AppStorage("fatGoal") private var fatGoal = 70.0

    // UI State
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @State private var showingAdd = false
    @State private var showingSearch = false
    @State private var editingEntry: FoodEntry?
    @State private var showDatePicker = false

    // Export support (broad query; UI uses day-scoped queries)
    @Query(sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)])
    private var allEntries: [FoodEntry]

    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.calendar = .current
        df.dateFormat = "EEE, MMM d, yyyy"
        return df
    }()

    private var entriesForExport: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }

    private var startOfDay: Date { Calendar.current.startOfDay(for: selectedDay) }
    private var endOfDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDay }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    DateHeaderView(
                        selectedDay: selectedDay,
                        dayFormatter: Self.dayFormatter,
                        onPreviousDay: { changeDay(by: -1) },
                        onNextDay: { changeDay(by: 1) },
                        onDateTap: { showDatePicker = true }
                    )
                    .padding(.top, AppTheme.Spacing.xl)

                    DailyTotalsView(
                        start: startOfDay,
                        end: endOfDay,
                        calorieGoal: dailyCalorieGoal,
                        proteinGoal: proteinGoal,
                        carbGoal: carbGoal,
                        fatGoal: fatGoal
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Food Logs")
                            .font(AppTheme.Typography.title2)
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                            .padding(.horizontal, AppTheme.Spacing.screenPadding)

                        DailyEntriesSection(
                            start: startOfDay,
                            end: endOfDay,
                            onEntryTap: { entry in editingEntry = entry },
                            onEntryDelete: deleteEntry
                        )
                        .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    }

                    Spacer(minLength: 80)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Lean Log")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button { showingSearch = true } label: {
                            Image(systemName: AppTheme.Icons.search)
                                .font(.system(size: 17, weight: .semibold))   // uniform
                                .imageScale(.medium)                           // uniform
                                .frame(width: 44, height: 44)                  // equal tap target
                        }

                        ExportCSVButton(entries: entriesForExport, day: selectedDay)
                            .labelStyle(.iconOnly)
                            .font(.system(size: 17, weight: .semibold))       // uniform
                            .imageScale(.medium)                               // uniform
                            .frame(width: 44, height: 44)                      // equal tap target

                        Button { showingAdd = true } label: {
                            Image(systemName: AppTheme.Icons.add)
                                .font(.system(size: 17, weight: .semibold))   // uniform
                                .imageScale(.medium)                           // uniform
                                .frame(width: 44, height: 44)                  // equal tap target
                        }
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDay: $selectedDay, onDismiss: { showDatePicker = false })
            }
            .sheet(isPresented: $showingAdd) {
                AddFoodView(defaultDate: selectedDay)
            }
            .sheet(isPresented: $showingSearch) {
                FoodSearchView()
            }
            .sheet(item: $editingEntry) { entry in
                EditFoodView(entry: entry)
            }
        }
    }

    // MARK: - Actions
    private func changeDay(by days: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedDay = Calendar.current.date(byAdding: .day, value: days, to: selectedDay) ?? selectedDay
            selectedDay = Calendar.current.startOfDay(for: selectedDay)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
        do { try modelContext.save() } catch {
            print("Error deleting entry: \(error)")
        }
    }
}

// MARK: - Daily Totals

private struct DailyTotalsView: View {
    let start: Date
    let end: Date
    let calorieGoal: Int
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double

    @Query private var entries: [FoodEntry]

    init(start: Date, end: Date, calorieGoal: Int, proteinGoal: Double, carbGoal: Double, fatGoal: Double) {
        self.start = start
        self.end = end
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)]
        )
    }

    private var totalCalories: Int { entries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { entries.reduce(0) { $0 + ($1.protein ?? 0) } }
    private var totalCarbs: Double { entries.reduce(0) { $0 + ($1.carbs ?? 0) } }
    private var totalFat: Double { entries.reduce(0) { $0 + ($1.fat ?? 0) } }

    var body: some View {
        MacroGoalsView(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            carbGoal: carbGoal,
            fatGoal: fatGoal
        )
    }
}

// MARK: - Daily Entries

private struct DailyEntriesSection: View {
    let start: Date
    let end: Date
    let onEntryTap: (FoodEntry) -> Void
    let onEntryDelete: (FoodEntry) -> Void

    @Query private var entries: [FoodEntry]

    init(start: Date, end: Date, onEntryTap: @escaping (FoodEntry) -> Void, onEntryDelete: @escaping (FoodEntry) -> Void) {
        self.start = start
        self.end = end
        self.onEntryTap = onEntryTap
        self.onEntryDelete = onEntryDelete
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Build an array of pairs (previous, current) to keep the builder tiny
            let pairs: [(previous: FoodEntry?, current: FoodEntry)] = {
                var result: [(FoodEntry?, FoodEntry)] = []
                result.reserveCapacity(entries.count)
                var prev: FoodEntry? = nil
                for e in entries {
                    result.append((prev, e))
                    prev = e
                }
                return result
            }()

            ForEach(pairs, id: \.current.id) { pair in
                DailyEntryRowContainer(
                    entry: pair.current,
                    previousEntry: pair.previous,
                    onTap: { onEntryTap(pair.current) },
                    onDelete: { onEntryDelete(pair.current) }
                )
            }

            if entries.isEmpty {
                EmptyStateView()
                    .padding(.vertical, AppTheme.Spacing.xl)
            }
        }
    }
}

// Minimal wrapper so complex modifiers aren’t inline
private struct DailyEntryRowContainer: View {
    let entry: FoodEntry
    let previousEntry: FoodEntry?
    let onTap: () -> Void
    let onDelete: () -> Void

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        VStack(spacing: 0) {
            if let prev = previousEntry {
                TimeGapIndicator(previousEntry: prev, currentEntry: entry)
            }
            FoodEntryRow(entry: entry, timeFormatter: Self.timeFormatter, onTap: onTap)
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive, action: onDelete)
                }
        }
    }
}

// MARK: - Components

struct FoodEntryRow: View {
    let entry: FoodEntry
    let timeFormatter: DateFormatter
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                rowHeader
                if hasNutritionInfo { macroRow }
            }
        }
        .buttonStyle(.plain)
        .modernCard()
    }

    private var rowHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Image(systemName: AppTheme.Icons.clock)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                    Text(timeFormatter.string(from: entry.timestamp))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: AppTheme.Icons.calories)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.calories)
                    Text("\(entry.calories) kcal")
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                }

                if let servingSize = entry.servingSize, servingSize > 0 {
                    let unit = entry.servingUnit ?? ""
                    Text("\(String(format: "%.1f", servingSize))\(unit)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                }
            }
        }
    }

    private var macroRow: some View {
        HStack(spacing: 10) {
            Text("P \(String(format: "%.1f", entry.protein ?? 0))g")
                .foregroundStyle(AppTheme.Colors.protein)
            Text("•")
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            Text("C \(String(format: "%.1f", entry.carbs ?? 0))g")
                .foregroundStyle(AppTheme.Colors.carbs)
            Text("•")
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            Text("F \(String(format: "%.1f", entry.fat ?? 0))g")
                .foregroundStyle(AppTheme.Colors.fat)
            Spacer()
        }
        .font(AppTheme.Typography.caption)
    }

    private var hasNutritionInfo: Bool {
        Self.hasMacros(entry)
    }

    private static func hasMacros(_ e: FoodEntry) -> Bool {
        let p: Double = e.protein ?? 0
        let c: Double = e.carbs ?? 0
        let f: Double = e.fat ?? 0
        return (p + c + f) > 0
    }
}

struct TimeGapIndicator: View {
    let previousEntry: FoodEntry
    let currentEntry: FoodEntry

    private var timeGap: TimeInterval {
        abs(previousEntry.timestamp.timeIntervalSince(currentEntry.timestamp))
    }

    private var gapText: String {
        let totalSeconds = Int(timeGap)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours >= 1 {
            return minutes == 0 ? "\(hours)h later" : "\(hours)h \(minutes)m later"
        } else if minutes >= 1 {
            return "\(minutes)m later"
        } else {
            return "shortly after"
        }
    }

    private var shouldShowGap: Bool { timeGap >= 300 }

    var body: some View {
        if shouldShowGap {
            VStack(spacing: AppTheme.Spacing.sm) {
                Spacer().frame(height: AppTheme.Spacing.lg)
                HStack {
                    Rectangle()
                        .fill(AppTheme.Colors.labelSecondary.opacity(0.25))
                        .frame(height: 1)
                        .frame(maxWidth: 40)
                    Text(gapText)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.input)
                                .overlay {
                                    Capsule().stroke(AppTheme.Colors.subtleStroke, lineWidth: 1)
                                }
                        )
                    Rectangle()
                        .fill(AppTheme.Colors.labelSecondary.opacity(0.25))
                        .frame(height: 1)
                        .frame(maxWidth: 40)
                }
                Spacer().frame(height: AppTheme.Spacing.lg)
            }
        } else {
            Spacer().frame(height: AppTheme.Spacing.md)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.labelSecondary)

            Text("No food logged today")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelSecondary)

            Text("Tap the + button to add your first meal")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.labelTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .padding(.horizontal, AppTheme.Spacing.screenPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(AppTheme.Colors.cardStrokeGradient, lineWidth: 1)
                }
        )
        .padding(.top, AppTheme.Spacing.lg)
    }
}

// DateHeaderView themed
struct DateHeaderView: View {
    let selectedDay: Date
    let dayFormatter: DateFormatter
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onDateTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onPreviousDay) {
                Image(systemName: AppTheme.Icons.back)
                    .font(.title3)
            }
            Spacer()
            Button(action: onDateTap) {
                Text(dayFormatter.string(from: selectedDay))
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select date")
            Spacer()
            Button(action: onNextDay) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screenPadding)
    }
}
