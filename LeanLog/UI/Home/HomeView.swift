//
//  HomeView.swift
//  LeanLog
//
//  Updated: After scanning (OFF), present AddFoodView with Prefill for editing before save.
//  Scanner callback now includes barcode so AddFoodView can enrich micros.
//  Helper subviews kept inline for scope.
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
    @State private var showingSearch = false
    @State private var showingBarcodeScanner = false
    @State private var showingQuickAdd = false
    @State private var editingEntry: FoodEntry?
    @State private var showDatePicker = false

    // Pending scanned draft to edit - updated with all micronutrient fields
    struct ScannedDraft: Identifiable {
        let id = UUID()
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let servingSize: Double
        let servingUnit: String
        let barcode: String?

        // All micros - kept nil for forward compatibility (will be enriched by AddFoodView)
        let sugars: Double? = nil
        let fiber: Double? = nil
        let saturatedFat: Double? = nil
        let transFat: Double? = nil
        let monounsaturatedFat: Double? = nil
        let polyunsaturatedFat: Double? = nil
        let cholesterol: Double? = nil
        let sodium: Double? = nil
        let salt: Double? = nil
        let potassium: Double? = nil
        let calcium: Double? = nil
        let iron: Double? = nil
        let magnesium: Double? = nil
        let phosphorus: Double? = nil
        let zinc: Double? = nil
        let selenium: Double? = nil
        let copper: Double? = nil
        let manganese: Double? = nil
        let chromium: Double? = nil
        let molybdenum: Double? = nil
        let iodine: Double? = nil
        let chloride: Double? = nil
        let vitaminA: Double? = nil
        let vitaminC: Double? = nil
        let vitaminD: Double? = nil
        let vitaminE: Double? = nil
        let vitaminK: Double? = nil
        let thiamin: Double? = nil
        let riboflavin: Double? = nil
        let niacin: Double? = nil
        let pantothenicAcid: Double? = nil
        let vitaminB6: Double? = nil
        let biotin: Double? = nil
        let folate: Double? = nil
        let vitaminB12: Double? = nil
        let choline: Double? = nil
    }
    @State private var scannedDraft: ScannedDraft?

    // Export support
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
            ZStack(alignment: .bottomTrailing) {
                // Main Content
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

                        Spacer(minLength: 120)
                    }
                }
                .screenBackground()

                FloatingActionButton(
                    onScan: { showingBarcodeScanner = true },
                    onSearch: { showingSearch = true },
                    onQuickAdd: { showingQuickAdd = true }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Logs")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ExportCSVButton(entries: entriesForExport, day: selectedDay)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 17, weight: .semibold))
                        .imageScale(.medium)
                        .frame(width: 44, height: 44)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDay: $selectedDay, onDismiss: { showDatePicker = false })
            }
            .sheet(isPresented: $showingQuickAdd) {
                AddFoodView(defaultDate: selectedDay) // manual add
            }
            .sheet(isPresented: $showingSearch) {
                FoodSearchView()
            }
            .fullScreenCover(isPresented: $showingBarcodeScanner) {
                // Updated scanner closure includes barcode
                BarcodeScannerWrapper { name, calories, protein, carbs, fat, servingSize, servingUnit, barcode in
                    scannedDraft = ScannedDraft(
                        name: name,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        servingSize: servingSize,
                        servingUnit: servingUnit,
                        barcode: barcode
                    )
                }
            }
            .sheet(item: $scannedDraft) { draft in
                AddFoodView(
                    defaultDate: selectedDay,
                    prefill: .init(
                        name: draft.name,
                        calories: draft.calories,
                        protein: draft.protein,
                        carbs: draft.carbs,
                        fat: draft.fat,
                        servingSize: draft.servingSize,
                        servingUnit: draft.servingUnit,
                        source: "OFF",
                        externalId: draft.barcode,
                        // Carb details
                        sugars: draft.sugars,
                        fiber: draft.fiber,
                        // Fat details
                        saturatedFat: draft.saturatedFat,
                        transFat: draft.transFat,
                        monounsaturatedFat: draft.monounsaturatedFat,
                        polyunsaturatedFat: draft.polyunsaturatedFat,
                        // Cholesterol & sodium
                        cholesterol: draft.cholesterol,
                        sodium: draft.sodium,
                        salt: draft.salt,
                        // Major minerals
                        potassium: draft.potassium,
                        calcium: draft.calcium,
                        iron: draft.iron,
                        magnesium: draft.magnesium,
                        phosphorus: draft.phosphorus,
                        zinc: draft.zinc,
                        // Trace minerals
                        selenium: draft.selenium,
                        copper: draft.copper,
                        manganese: draft.manganese,
                        chromium: draft.chromium,
                        molybdenum: draft.molybdenum,
                        iodine: draft.iodine,
                        chloride: draft.chloride,
                        // Vitamins
                        vitaminA: draft.vitaminA,
                        vitaminC: draft.vitaminC,
                        vitaminD: draft.vitaminD,
                        vitaminE: draft.vitaminE,
                        vitaminK: draft.vitaminK,
                        // B Vitamins
                        thiamin: draft.thiamin,
                        riboflavin: draft.riboflavin,
                        niacin: draft.niacin,
                        pantothenicAcid: draft.pantothenicAcid,
                        vitaminB6: draft.vitaminB6,
                        biotin: draft.biotin,
                        folate: draft.folate,
                        vitaminB12: draft.vitaminB12,
                        // Other
                        choline: draft.choline
                    )
                )
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

// MARK: - Floating Action Button (no context menu)

struct FloatingActionButton: View {
    let onScan: () -> Void
    let onSearch: () -> Void
    let onQuickAdd: () -> Void
    @State private var showDialog = false

    var body: some View {
        Button { showDialog = true } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGradient)
                    .frame(width: AppTheme.FAB.size, height: AppTheme.FAB.size)
                    .shadow(color: .black.opacity(AppTheme.FAB.shadowOpacity),
                            radius: AppTheme.FAB.shadowRadius,
                            y: AppTheme.FAB.shadowY)
                Image(systemName: AppTheme.Icons.add)
                    .font(.system(size: AppTheme.FAB.iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .confirmationDialog("Add Food", isPresented: $showDialog, titleVisibility: .visible) {
            Button("Scan Barcode") { onScan() }
            Button("Search Foods") { onSearch() }
            Button("Quick Add") { onQuickAdd() }
            Button("Cancel", role: .cancel) { }
        }
        .padding(.trailing, AppTheme.FAB.trailingPadding)
        .padding(.bottom, AppTheme.FAB.bottomPadding)
    }
}

// MARK: - Date Header

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

            Text("Tap the + button to add food")
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
