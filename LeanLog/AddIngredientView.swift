//
//  AddIngredientView.swift
//  LeanLog
//
//  Simplified: Native keyboard + tap-to-dismiss
//

import SwiftUI
import SwiftData
import UIKit

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onIngredientAdded: (MealIngredient) -> Void

    enum Mode: String, CaseIterable, Identifiable {
        case search = "Search", manual = "Manual", recent = "Recent"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .manual

    // Manual fields
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = ""

    @FocusState private var focused: ManualField?
    enum ManualField: Hashable { case name, size, unit, cals, prot, carbs, fat }

    // Search
    @State private var query = ""
    @State private var results: [FDCSearchFood] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    private let usda = USDAService(apiKey: Secrets.usdaApiKey)

    // Recent
    @Query(sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)])
    private var allEntries: [FoodEntry]

    // Locale-aware number IO (shared utility)
    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    private var isManualValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(calories) != nil
    }

    private var manualFieldOrder: [ManualField] {
        [.name, .size, .unit, .cals, .prot, .carbs, .fat]
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {

                        // Prominent large segmented tabs
                        Picker("", selection: $mode) {
                            ForEach(Mode.allCases) { m in
                                Text(m.rawValue)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                    .tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                        .tint(AppTheme.Colors.accent)

                        Group {
                            switch mode {
                            case .search:
                                searchCard.modernCard()
                                searchResultsList
                            case .manual:
                                manualDetailsCard.modernCard()
                                manualNutritionCard.modernCard()
                                addButton
                            case .recent:
                                recentList
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.bottom, 20)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focused = nil
                }
                .onChange(of: focused) { _ in
                    scrollFocusedIntoView(proxy)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Ingredient")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: AppTheme.Icons.close)
                            .imageScale(.medium)
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    // MARK: - Manual

    private var manualDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Ingredient details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                TextField("Ingredient name", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .keyboardType(.default)
                    .focused($focused, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focused = .size }
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
            }
            .modernField(focused: focused == .name)
            .id(ManualField.name)

            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "scalemass")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Serving size", text: $servingSize)
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: .size)
                        .submitLabel(.next)
                        .onSubmit { focused = .unit }
                        .onChange(of: servingSize) { newValue in
                            servingSize = numberIO.sanitizeDecimal(newValue)
                        }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focused == .size)
                .id(ManualField.size)

                TextField("Unit (e.g., g, oz)", text: $servingUnit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($focused, equals: .unit)
                    .submitLabel(.next)
                    .onSubmit { focused = .cals }
                    .modernField(focused: focused == .unit)
                    .frame(maxWidth: 160)
                    .id(ManualField.unit)
            }
        }
    }

    private var manualNutritionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Nutrition (per serving)")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            let columns: [GridItem] = [
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
            ]

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                macroField(
                    icon: AppTheme.Icons.calories,
                    title: "Calories",
                    unit: "kcal",
                    color: AppTheme.Colors.calories,
                    text: $calories,
                    field: .cals,
                    keyboard: .numberPad,
                    sanitizer: { numberIO.sanitizeInteger($0) }
                )
                .id(ManualField.cals)

                macroField(
                    icon: AppTheme.Icons.protein,
                    title: "Protein",
                    unit: "g",
                    color: AppTheme.Colors.protein,
                    text: $protein,
                    field: .prot,
                    keyboard: .decimalPad,
                    sanitizer: { numberIO.sanitizeDecimal($0) }
                )
                .id(ManualField.prot)

                macroField(
                    icon: AppTheme.Icons.carbs,
                    title: "Carbs",
                    unit: "g",
                    color: AppTheme.Colors.carbs,
                    text: $carbs,
                    field: .carbs,
                    keyboard: .decimalPad,
                    sanitizer: { numberIO.sanitizeDecimal($0) }
                )
                .id(ManualField.carbs)

                macroField(
                    icon: AppTheme.Icons.fat,
                    title: "Fat",
                    unit: "g",
                    color: AppTheme.Colors.fat,
                    text: $fat,
                    field: .fat,
                    keyboard: .decimalPad,
                    sanitizer: { numberIO.sanitizeDecimal($0) }
                )
                .id(ManualField.fat)
            }
        }
    }

    private func advance(from field: ManualField) {
        if let idx = manualFieldOrder.firstIndex(of: field), idx < manualFieldOrder.count - 1 {
            focused = manualFieldOrder[idx + 1]
        } else {
            focused = nil
        }
    }

    private func macroField(
        icon: String,
        title: String,
        unit: String,
        color: Color,
        text: Binding<String>,
        field: ManualField,
        keyboard: UIKeyboardType,
        sanitizer: @escaping (String) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 22)
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            HStack {
                TextField("0", text: text)
                    .keyboardType(keyboard)
                    .focused($focused, equals: field)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .submitLabel(field == .fat ? .done : .next)
                    .onSubmit {
                        if field == .fat {
                            focused = nil
                        } else {
                            advance(from: field)
                        }
                    }
                    .onChange(of: text.wrappedValue) { newValue in
                        let sanitized = sanitizer(newValue)
                        if sanitized != newValue {
                            text.wrappedValue = sanitized
                        }
                    }

                Text(unit)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            .modernField(focused: focused == field)
        }
    }

    private var addButton: some View {
        Button(action: addManualIngredient) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: AppTheme.Icons.add)
                Text("Add Ingredient")
                    .font(AppTheme.Typography.bodyEmphasized)
                    .lineLimit(1)
                    .minimumScaleFactor(0.95)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.accentGradient)
            )
        }
        .disabled(!isManualValid)
        .opacity(isManualValid ? 1 : 0.5)
    }

    // MARK: - Search

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Search USDA")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: AppTheme.Icons.search)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                TextField("Search foods…", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .onChange(of: query) { _, _ in
                        debounceSearch()
                    }
            }
            .modernField()

            if searching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }

    private var searchResultsList: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(results) { item in
                Button {
                    Task {
                        await selectSearchItem(item)
                    }
                } label: {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.description)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                                .lineLimit(2)
                            if let brand = item.brandName {
                                Text(brand)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                    }
                    .padding(AppTheme.Spacing.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .fill(AppTheme.Colors.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.cardStrokeGradient, lineWidth: 1)
                            }
                    )
                }
                .buttonStyle(.plain)
            }

            if !query.isEmpty && results.isEmpty && !searching {
                ContentUnavailableView("No results", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func debounceSearch() {
        searchTask?.cancel()
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else {
            results = []
            searching = false
            return
        }
        searchTask = Task { @MainActor in
            searching = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(term)
        }
    }

    @MainActor
    private func runSearch(_ term: String) async {
        do {
            let r = try await usda.searchFoods(query: term, pageSize: 20)
            guard term == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            results = r
            searching = false
        } catch {
            guard term == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            results = []
            searching = false
        }
    }

    private func selectSearchItem(_ item: FDCSearchFood) async {
        do {
            let d = try await usda.fetchFoodDetail(fdcId: item.fdcId)
            let m = d.extractMacros()
            let ing = MealIngredient(
                name: d.description ?? item.description,
                quantity: 1.0,
                calories: m.kcal,
                protein: m.protein,
                carbs: m.carbs,
                fat: m.fat,
                servingSize: d.actualServingSize,
                servingUnit: d.actualServingUnit,
                source: "USDA"
            )
            onIngredientAdded(ing)
            dismiss()
        } catch {
            print("USDA error: \(error)")
        }
    }

    // MARK: - Recent

    private var recentList: some View {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let unique = uniqueRecent(from: allEntries.filter { $0.timestamp >= thirtyDaysAgo })

        return VStack(spacing: AppTheme.Spacing.md) {
            if unique.isEmpty {
                ContentUnavailableView(
                    "No Recent Foods",
                    systemImage: "clock",
                    description: Text("Foods logged in the last 30 days will appear here")
                )
                .frame(maxWidth: .infinity)
            } else {
                ForEach(unique.prefix(20), id: \.id) { entry in
                    Button {
                        selectRecent(entry)
                    } label: {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.name)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                                HStack(spacing: 8) {
                                    Text("\(entry.calories) kcal")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.calories)
                                    if let p = entry.protein, p > 0 {
                                        Text("• P \(String(format: "%.1f", p))g")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                                    }
                                    if let src = entry.source {
                                        Text("• \(src)")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(AppTheme.Colors.labelTertiary)
                        }
                        .padding(AppTheme.Spacing.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .fill(AppTheme.Colors.surface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                        .strokeBorder(AppTheme.Colors.cardStrokeGradient, lineWidth: 1)
                                }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func uniqueRecent(from entries: [FoodEntry]) -> [FoodEntry] {
        var seen = Set<String>()
        return entries.compactMap { e in
            let key = e.name.lowercased()
            if seen.contains(key) { return nil }
            seen.insert(key)
            return e
        }
    }

    private func selectRecent(_ entry: FoodEntry) {
        let ing = MealIngredient(
            name: entry.name,
            quantity: 1.0,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            servingSize: entry.servingSize,
            servingUnit: entry.servingUnit,
            source: entry.source
        )
        onIngredientAdded(ing)
        dismiss()
    }

    // MARK: - Actions

    private func addManualIngredient() {
        guard isManualValid else { return }
        let ing = MealIngredient(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: 1.0,
            calories: Int(calories) ?? 0,
            protein: protein.isEmpty ? nil : Double(protein),
            carbs: carbs.isEmpty ? nil : Double(carbs),
            fat: fat.isEmpty ? nil : Double(fat),
            servingSize: servingSize.isEmpty ? nil : Double(servingSize),
            servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Manual"
        )
        onIngredientAdded(ing)
        dismiss()
    }

    // MARK: - Keyboard scroll helper

    private func scrollFocusedIntoView(_ proxy: ScrollViewProxy) {
        guard let field = focused else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(field, anchor: .bottom)
        }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(field, anchor: .bottom)
            }
        }
    }
}
