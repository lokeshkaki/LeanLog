//
//  AddFoodView.swift
//  LeanLog
//
//  Native keyboard + tap-to-dismiss
//  Prefill supports OFF + USDA
//  Micronutrients enrichment on appear when barcode available (OFF)
//

import SwiftUI
import SwiftData
import UIKit

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.dynamicTypeSize) private var dynType

    let defaultDate: Date

    // optional prefill for scanned items (or other sources)
    struct Prefill: Sendable {
        let name: String?
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let servingSize: Double?
        let servingUnit: String?
        let source: String?          // "OFF", "USDA", "Manual"
        let externalId: String?      // e.g., barcode (OFF) or fdcId (USDA)

        // Carb details
        let sugars: Double?
        let fiber: Double?
        
        // Fat details
        let saturatedFat: Double?
        let transFat: Double?
        let monounsaturatedFat: Double?
        let polyunsaturatedFat: Double?
        
        // Cholesterol & sodium
        let cholesterol: Double?
        let sodium: Double?
        let salt: Double?
        
        // Major minerals
        let potassium: Double?
        let calcium: Double?
        let iron: Double?
        let magnesium: Double?
        let phosphorus: Double?
        let zinc: Double?
        
        // Trace minerals
        let selenium: Double?
        let copper: Double?
        let manganese: Double?
        let chromium: Double?
        let molybdenum: Double?
        let iodine: Double?
        let chloride: Double?
        
        // Vitamins
        let vitaminA: Double?
        let vitaminC: Double?
        let vitaminD: Double?
        let vitaminE: Double?
        let vitaminK: Double?
        
        // B Vitamins
        let thiamin: Double?
        let riboflavin: Double?
        let niacin: Double?
        let pantothenicAcid: Double?
        let vitaminB6: Double?
        let biotin: Double?
        let folate: Double?
        let vitaminB12: Double?
        
        // Other
        let choline: Double?
    }

    private let prefill: Prefill?

    // Fields - core
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var selectedDate: Date

    // Serving unit redesign: segmented with common units + Other
    private let unitOptions = ["g", "ml", "oz", "Other"]
    @State private var servingUnitChoice = "g"
    @State private var customUnit = ""

    // Fields - micros (all stored as grams per serving)
    // Carb details
    @State private var sugars = ""
    @State private var fiber = ""
    
    // Fat details
    @State private var saturatedFat = ""
    @State private var transFat = ""
    @State private var monounsaturatedFat = ""
    @State private var polyunsaturatedFat = ""
    
    // Cholesterol & sodium
    @State private var cholesterol = ""
    @State private var sodium = ""
    @State private var salt = ""
    
    // Major minerals
    @State private var potassium = ""
    @State private var calcium = ""
    @State private var iron = ""
    @State private var magnesium = ""
    @State private var phosphorus = ""
    @State private var zinc = ""
    
    // Trace minerals
    @State private var selenium = ""
    @State private var copper = ""
    @State private var manganese = ""
    @State private var chromium = ""
    @State private var molybdenum = ""
    @State private var iodine = ""
    @State private var chloride = ""
    
    // Vitamins
    @State private var vitaminA = ""
    @State private var vitaminC = ""
    @State private var vitaminD = ""
    @State private var vitaminE = ""
    @State private var vitaminK = ""
    
    // B Vitamins
    @State private var thiamin = ""
    @State private var riboflavin = ""
    @State private var niacin = ""
    @State private var pantothenicAcid = ""
    @State private var vitaminB6 = ""
    @State private var biotin = ""
    @State private var folate = ""
    @State private var vitaminB12 = ""
    
    // Other
    @State private var choline = ""

    // UI - collapsed by default
    @State private var showMicros = false
    @State private var enrichingMicros = false

    @FocusState private var focusedField: Field?

    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    enum Field: CaseIterable, Hashable {
        case name, servingSize, calories, protein, carbs, fat, customUnit
    }

    init(defaultDate: Date, prefill: Prefill? = nil) {
        self.defaultDate = defaultDate
        self.prefill = prefill
        let sod = Calendar.current.startOfDay(for: defaultDate)
        self._selectedDate = State(initialValue: sod)

        func fmt2(_ v: Double?) -> String {
            guard let v = v else { return "" }
            if v == floor(v) { return String(Int(v)) }
            return String(format: "%.2f", v)
        }

        // Convert grams to milligrams for display if needed
        func fmtMg(_ v: Double?) -> String {
            guard let v = v else { return "" }
            let mg = v * 1000
            if mg == floor(mg) { return String(Int(mg)) }
            return String(format: "%.2f", mg)
        }
        
        // Convert grams to micrograms for display
        func fmtMcg(_ v: Double?) -> String {
            guard let v = v else { return "" }
            let mcg = v * 1_000_000
            if mcg == floor(mcg) { return String(Int(mcg)) }
            return String(format: "%.2f", mcg)
        }

        _name = State(initialValue: prefill?.name ?? "")
        _calories = State(initialValue: prefill?.calories.map(String.init) ?? "")
        _protein = State(initialValue: fmt2(prefill?.protein))
        _carbs   = State(initialValue: fmt2(prefill?.carbs))
        _fat     = State(initialValue: fmt2(prefill?.fat))
        _servingSize = State(initialValue: fmt2(prefill?.servingSize))

        // Unit seed
        let u = (prefill?.servingUnit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if u.isEmpty || u == "g" || u == "ml" || u == "oz" {
            _servingUnitChoice = State(initialValue: u.isEmpty ? "g" : u)
            _customUnit = State(initialValue: "")
        } else {
            _servingUnitChoice = State(initialValue: "Other")
            _customUnit = State(initialValue: u)
        }

        // Carb details
        _sugars = State(initialValue: fmt2(prefill?.sugars))
        _fiber = State(initialValue: fmt2(prefill?.fiber))
        
        // Fat details
        _saturatedFat = State(initialValue: fmt2(prefill?.saturatedFat))
        _transFat = State(initialValue: fmt2(prefill?.transFat))
        _monounsaturatedFat = State(initialValue: fmt2(prefill?.monounsaturatedFat))
        _polyunsaturatedFat = State(initialValue: fmt2(prefill?.polyunsaturatedFat))
        
        // Cholesterol & sodium - display in mg
        _cholesterol = State(initialValue: fmtMg(prefill?.cholesterol))
        _sodium = State(initialValue: fmtMg(prefill?.sodium))
        _salt = State(initialValue: fmt2(prefill?.salt))
        
        // Major minerals - display in mg
        _potassium = State(initialValue: fmtMg(prefill?.potassium))
        _calcium = State(initialValue: fmtMg(prefill?.calcium))
        _iron = State(initialValue: fmtMg(prefill?.iron))
        _magnesium = State(initialValue: fmtMg(prefill?.magnesium))
        _phosphorus = State(initialValue: fmtMg(prefill?.phosphorus))
        _zinc = State(initialValue: fmtMg(prefill?.zinc))
        
        // Trace minerals - display in mcg
        _selenium = State(initialValue: fmtMcg(prefill?.selenium))
        _copper = State(initialValue: fmtMg(prefill?.copper))
        _manganese = State(initialValue: fmtMg(prefill?.manganese))
        _chromium = State(initialValue: fmtMcg(prefill?.chromium))
        _molybdenum = State(initialValue: fmtMcg(prefill?.molybdenum))
        _iodine = State(initialValue: fmtMcg(prefill?.iodine))
        _chloride = State(initialValue: fmtMg(prefill?.chloride))
        
        // Vitamins
        _vitaminA = State(initialValue: fmtMcg(prefill?.vitaminA))
        _vitaminC = State(initialValue: fmtMg(prefill?.vitaminC))
        _vitaminD = State(initialValue: fmtMcg(prefill?.vitaminD))
        _vitaminE = State(initialValue: fmtMg(prefill?.vitaminE))
        _vitaminK = State(initialValue: fmtMcg(prefill?.vitaminK))
        
        // B Vitamins
        _thiamin = State(initialValue: fmtMg(prefill?.thiamin))
        _riboflavin = State(initialValue: fmtMg(prefill?.riboflavin))
        _niacin = State(initialValue: fmtMg(prefill?.niacin))
        _pantothenicAcid = State(initialValue: fmtMg(prefill?.pantothenicAcid))
        _vitaminB6 = State(initialValue: fmtMg(prefill?.vitaminB6))
        _biotin = State(initialValue: fmtMcg(prefill?.biotin))
        _folate = State(initialValue: fmtMcg(prefill?.folate))
        _vitaminB12 = State(initialValue: fmtMcg(prefill?.vitaminB12))
        
        // Other
        _choline = State(initialValue: fmtMg(prefill?.choline))
    }

    private var orderedFields: [Field] {
        [.name, .servingSize, .calories, .protein, .carbs, .fat, .customUnit]
    }

    // Adaptive rule for unit control: segmented when space is ample and not in accessibility sizes
    private var useSegmentedUnits: Bool {
        (hSizeClass != .compact) && (dynType < .accessibility1)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {

                        // Compact review note (replaces large card)
                        reviewNoteRow

                        // Details
                        nameServingCard.modernCard()

                        // Macros
                        macrosGridCard.modernCard()

                        // Additional Nutrients (collapsed by default, read-only)
                        microsCard.modernCard()

                        // Log details
                        logDetailsCard.modernCard()

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.lg)
                }
                // Tap anywhere to dismiss keyboard
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
                .onChange(of: focusedField) { _ in
                    if let f = focusedField {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(f, anchor: .center)
                        }
                    }
                }
            }
            .screenBackground()
            .navigationTitle(prefill == nil ? "Add Food" : "Review")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
            // Keyboard toolbar with Done button as fallback
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close).imageScale(.medium)
                    }.accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveFood) {
                        Image(systemName: AppTheme.Icons.save).symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.4)
                    .accessibilityLabel("Save")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                }
            }
            .task {
                // Enrich micros if scanned from OFF and barcode present but micros empty
                await maybeEnrichMicrosFromOFF()
            }
        }
    }

    // MARK: - Compact note

    private var noteText: String {
        prefill == nil
        ? "Enter details to add this food to the log."
        : "Confirm details, then save to the log."
    }

    private var reviewNoteRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.Colors.accent)
            Text(noteText)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(AppTheme.Colors.input)
        )
    }

    // MARK: - Sections

    private var nameServingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Food details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                TextField("Food name", text: $name, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .keyboardType(.default)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .servingSize }
                    .lineLimit(1...3)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .modernField(focused: focusedField == .name)
                    .id(Field.name)

                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Name is required.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                }
            }

            // Serving - unified size and unit in a single intuitive row
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Serving")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
                    // Size input - takes 65% of space
                    TextField("Amount", text: $servingSize)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .servingSize)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .calories }
                        .onChange(of: servingSize) { servingSize = numberIO.sanitizeDecimal($0) }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .multilineTextAlignment(.leading)
                        .modernField(focused: focusedField == .servingSize)
                        .id(Field.servingSize)
                    
                    // Unit picker - takes 35% of space
                    if useSegmentedUnits {
                        Picker("", selection: $servingUnitChoice) {
                            ForEach(unitOptions, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(minWidth: 160)
                    } else {
                        Menu {
                            Picker("", selection: $servingUnitChoice) {
                                ForEach(unitOptions, id: \.self) { Text($0) }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(servingUnitChoice)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .frame(minWidth: 90)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                                    .fill(AppTheme.Colors.input)
                            )
                        }
                    }
                }

                // Custom unit (only when "Other" is selected)
                if servingUnitChoice == "Other" {
                    TextField("Custom unit (e.g., cup, tbsp)", text: $customUnit)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .customUnit)
                        .submitLabel(.done)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .modernField(focused: focusedField == .customUnit)
                        .id(Field.customUnit)
                }
            }

        }
    }

    private var macrosGridCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Macros")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            let columns = [
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
            ]

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                macroField(icon: AppTheme.Icons.calories, title: "Calories", unit: "kcal",
                           color: AppTheme.Colors.calories, text: $calories, field: .calories,
                           keyboard: .numberPad, sanitizer: { numberIO.sanitizeInteger($0) })
                    .id(Field.calories)

                macroField(icon: AppTheme.Icons.protein, title: "Protein", unit: "g",
                           color: AppTheme.Colors.protein, text: $protein, field: .protein,
                           keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
                    .id(Field.protein)

                macroField(icon: AppTheme.Icons.carbs, title: "Carbs", unit: "g",
                           color: AppTheme.Colors.carbs, text: $carbs, field: .carbs,
                           keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
                    .id(Field.carbs)

                macroField(icon: AppTheme.Icons.fat, title: "Fat", unit: "g",
                           color: AppTheme.Colors.fat, text: $fat, field: .fat,
                           keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
                    .id(Field.fat)
            }
        }
    }

    private func macroField(
        icon: String,
        title: String,
        unit: String,
        color: Color,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType,
        sanitizer: @escaping (String) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon).symbolRenderingMode(.hierarchical).foregroundStyle(color).frame(width: 22)
                Text(title).font(AppTheme.Typography.callout).foregroundStyle(AppTheme.Colors.labelSecondary)
            }
            HStack {
                TextField(title, text: text)
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: field)
                    .onChange(of: text.wrappedValue) { text.wrappedValue = sanitizer($0) }
                    .submitLabel(nextField(after: field) == nil ? .done : .next)
                    .onSubmit {
                        if let next = nextField(after: field) { focusedField = next } else { focusedField = nil }
                    }
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text(unit)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            .modernField(focused: focusedField == field)
        }
    }

    private func nextField(after field: Field) -> Field? {
        guard let idx = orderedFields.firstIndex(of: field) else { return nil }
        let next = orderedFields.index(after: idx)
        return next < orderedFields.endIndex ? orderedFields[next] : nil
    }

    private var microsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            HStack {
                Text("Nutrition Details")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Spacer()
                Button(action: { withAnimation(.easeInOut) { showMicros.toggle() } }) {
                    HStack(spacing: 6) {
                        Text(showMicros ? "Hide" : "Show").font(AppTheme.Typography.callout)
                        Image(systemName: showMicros ? "chevron.up" : "chevron.down").font(.footnote)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.Colors.accent)
            }

            if showMicros {
                if hasAnyMicronutrients {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Carbohydrate Details
                        if hasCarbDetails {
                            NutrientSection(title: "Carbohydrates", icon: "leaf.fill") {
                                nutrientRow("Sugars", value: sugars, unit: "g")
                                nutrientRow("Fiber", value: fiber, unit: "g")
                            }
                        }
                        
                        // Fat Details
                        if hasFatDetails {
                            NutrientSection(title: "Fats", icon: "drop.fill") {
                                nutrientRow("Saturated Fat", value: saturatedFat, unit: "g")
                                nutrientRow("Trans Fat", value: transFat, unit: "g")
                                nutrientRow("Monounsaturated", value: monounsaturatedFat, unit: "g")
                                nutrientRow("Polyunsaturated", value: polyunsaturatedFat, unit: "g")
                                nutrientRow("Cholesterol", value: cholesterol, unit: "mg")
                            }
                        }
                        
                        // Sodium & Salt
                        if hasSodiumSalt {
                            NutrientSection(title: "Sodium", icon: "saltshaker.fill") {
                                nutrientRow("Sodium", value: sodium, unit: "mg")
                                nutrientRow("Salt", value: salt, unit: "g")
                            }
                        }
                        
                        // Major Minerals
                        if hasMajorMinerals {
                            NutrientSection(title: "Major Minerals", icon: "circle.hexagongrid.fill") {
                                nutrientRow("Potassium", value: potassium, unit: "mg")
                                nutrientRow("Calcium", value: calcium, unit: "mg")
                                nutrientRow("Iron", value: iron, unit: "mg")
                                nutrientRow("Magnesium", value: magnesium, unit: "mg")
                                nutrientRow("Phosphorus", value: phosphorus, unit: "mg")
                                nutrientRow("Zinc", value: zinc, unit: "mg")
                            }
                        }
                        
                        // Trace Minerals
                        if hasTraceMinerals {
                            NutrientSection(title: "Trace Minerals", icon: "sparkles") {
                                nutrientRow("Selenium", value: selenium, unit: "mcg")
                                nutrientRow("Copper", value: copper, unit: "mg")
                                nutrientRow("Manganese", value: manganese, unit: "mg")
                                nutrientRow("Chromium", value: chromium, unit: "mcg")
                                nutrientRow("Molybdenum", value: molybdenum, unit: "mcg")
                                nutrientRow("Iodine", value: iodine, unit: "mcg")
                                nutrientRow("Chloride", value: chloride, unit: "mg")
                            }
                        }
                        
                        // Vitamins
                        if hasVitamins {
                            NutrientSection(title: "Vitamins", icon: "sun.max.fill") {
                                nutrientRow("Vitamin A", value: vitaminA, unit: "mcg")
                                nutrientRow("Vitamin C", value: vitaminC, unit: "mg")
                                nutrientRow("Vitamin D", value: vitaminD, unit: "mcg")
                                nutrientRow("Vitamin E", value: vitaminE, unit: "mg")
                                nutrientRow("Vitamin K", value: vitaminK, unit: "mcg")
                            }
                        }
                        
                        // B Vitamins
                        if hasBVitamins {
                            NutrientSection(title: "B Vitamins", icon: "circle.grid.2x2.fill") {
                                nutrientRow("Thiamin (B1)", value: thiamin, unit: "mg")
                                nutrientRow("Riboflavin (B2)", value: riboflavin, unit: "mg")
                                nutrientRow("Niacin (B3)", value: niacin, unit: "mg")
                                nutrientRow("Pantothenic Acid (B5)", value: pantothenicAcid, unit: "mg")
                                nutrientRow("Vitamin B6", value: vitaminB6, unit: "mg")
                                nutrientRow("Biotin (B7)", value: biotin, unit: "mcg")
                                nutrientRow("Folate (B9)", value: folate, unit: "mcg")
                                nutrientRow("Vitamin B12", value: vitaminB12, unit: "mcg")
                            }
                        }
                        
                        // Other Nutrients
                        if hasOtherNutrients {
                            NutrientSection(title: "Other Nutrients", icon: "star.fill") {
                                nutrientRow("Choline", value: choline, unit: "mg")
                            }
                        }
                    }
                } else {
                    Text("No additional nutrition information available")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppTheme.Spacing.md)
                }
            }
        }
    }
    
    // MARK: - Nutrient Section Component
    
    private struct NutrientSection<Content: View>: View {
        let title: String
        let icon: String
        @ViewBuilder let content: Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(width: 18)
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                VStack(spacing: 1) {
                    content
                }
                .background(AppTheme.Colors.input)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            }
        }
    }
    
    // MARK: - Nutrient Row Component
    
    private func nutrientRow(_ label: String, value: String, unit: String) -> some View {
        Group {
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Text(label)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    Spacer()
                    Text("\(value) \(unit)")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.surface)
            }
        }
    }
    
    // MARK: - Nutrient Availability Helpers
    
    private var hasCarbDetails: Bool {
        !sugars.isEmpty || !fiber.isEmpty
    }
    
    private var hasFatDetails: Bool {
        !saturatedFat.isEmpty || !transFat.isEmpty || !monounsaturatedFat.isEmpty || !polyunsaturatedFat.isEmpty || !cholesterol.isEmpty
    }
    
    private var hasSodiumSalt: Bool {
        !sodium.isEmpty || !salt.isEmpty
    }
    
    private var hasMajorMinerals: Bool {
        !potassium.isEmpty || !calcium.isEmpty || !iron.isEmpty || !magnesium.isEmpty || !phosphorus.isEmpty || !zinc.isEmpty
    }
    
    private var hasTraceMinerals: Bool {
        !selenium.isEmpty || !copper.isEmpty || !manganese.isEmpty || !chromium.isEmpty || !molybdenum.isEmpty || !iodine.isEmpty || !chloride.isEmpty
    }
    
    private var hasVitamins: Bool {
        !vitaminA.isEmpty || !vitaminC.isEmpty || !vitaminD.isEmpty || !vitaminE.isEmpty || !vitaminK.isEmpty
    }
    
    private var hasBVitamins: Bool {
        !thiamin.isEmpty || !riboflavin.isEmpty || !niacin.isEmpty || !pantothenicAcid.isEmpty || !vitaminB6.isEmpty || !biotin.isEmpty || !folate.isEmpty || !vitaminB12.isEmpty
    }
    
    private var hasOtherNutrients: Bool {
        !choline.isEmpty
    }
    
    private var hasAnyMicronutrients: Bool {
        hasCarbDetails || hasFatDetails || hasSodiumSalt || hasMajorMinerals || hasTraceMinerals || hasVitamins || hasBVitamins || hasOtherNutrients
    }

    private var logDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Log details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .tint(AppTheme.Colors.accent)
            DatePicker("Time", selection: Binding(
                get: { selectedDate },
                set: { selectedDate = $0 }
            ), displayedComponents: [.hourAndMinute])
            .datePickerStyle(.compact)
            .tint(AppTheme.Colors.accent)
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(calories) != nil
    }

    // MARK: - Save

    private func saveFood() {
        let now = Date()
        let normalizedDay = Calendar.current.startOfDay(for: selectedDate)

        let finalUnit: String = {
            if servingUnitChoice == "Other" {
                let trimmed = customUnit.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "g" : trimmed
            } else {
                return servingUnitChoice
            }
        }()

        // Convert display values back to grams for storage
        func mgToG(_ str: String) -> Double? {
            guard let mg = numberIO.parseDouble(str) else { return nil }
            return mg / 1000
        }
        
        func mcgToG(_ str: String) -> Double? {
            guard let mcg = numberIO.parseDouble(str) else { return nil }
            return mcg / 1_000_000
        }

        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Int(calories) ?? 0,
            servingSize: numberIO.parseDouble(servingSize),
            servingUnit: finalUnit,
            date: normalizedDay,
            timestamp: merge(date: normalizedDay, timeFrom: selectedDate) ?? now,
            source: prefill?.source,
            externalId: prefill?.externalId,
            // Macros
            protein: numberIO.parseDouble(protein),
            carbs: numberIO.parseDouble(carbs),
            fat: numberIO.parseDouble(fat),
            // Carb details
            sugars: numberIO.parseDouble(sugars),
            fiber: numberIO.parseDouble(fiber),
            // Fat details
            saturatedFat: numberIO.parseDouble(saturatedFat),
            transFat: numberIO.parseDouble(transFat),
            monounsaturatedFat: numberIO.parseDouble(monounsaturatedFat),
            polyunsaturatedFat: numberIO.parseDouble(polyunsaturatedFat),
            // Cholesterol & sodium
            cholesterol: mgToG(cholesterol),
            sodium: mgToG(sodium),
            salt: numberIO.parseDouble(salt),
            // Major minerals
            potassium: mgToG(potassium),
            calcium: mgToG(calcium),
            iron: mgToG(iron),
            magnesium: mgToG(magnesium),
            phosphorus: mgToG(phosphorus),
            zinc: mgToG(zinc),
            // Trace minerals
            selenium: mcgToG(selenium),
            copper: mgToG(copper),
            manganese: mgToG(manganese),
            chromium: mcgToG(chromium),
            molybdenum: mcgToG(molybdenum),
            iodine: mcgToG(iodine),
            chloride: mgToG(chloride),
            // Vitamins
            vitaminA: mcgToG(vitaminA),
            vitaminC: mgToG(vitaminC),
            vitaminD: mcgToG(vitaminD),
            vitaminE: mgToG(vitaminE),
            vitaminK: mcgToG(vitaminK),
            // B Vitamins
            thiamin: mgToG(thiamin),
            riboflavin: mgToG(riboflavin),
            niacin: mgToG(niacin),
            pantothenicAcid: mgToG(pantothenicAcid),
            vitaminB6: mgToG(vitaminB6),
            biotin: mcgToG(biotin),
            folate: mcgToG(folate),
            vitaminB12: mcgToG(vitaminB12),
            // Other
            choline: mgToG(choline)
        )

        modelContext.insert(entry)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    // MARK: - Helpers

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        focusedField = nil
    }

    private func merge(date: Date, timeFrom: Date) -> Date? {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute, .second], from: timeFrom)
        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute
        comps.second = t.second
        return cal.date(from: comps)
    }

    private func maybeEnrichMicrosFromOFF() async {
        guard prefill?.source == "OFF",
              let barcode = prefill?.externalId,
              !barcode.isEmpty,
              !enrichingMicros else { return }

        enrichingMicros = true
        defer { enrichingMicros = false }

        do {
            let service = OpenFoodFactsService()
            let resolved = try await service.fetchResolvedFood(barcode)

            // Convert grams to appropriate display units
            func setMg(_ binding: inout String, from v: Double?) {
                if binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let v, v > 0 {
                    let mg = v * 1000
                    binding = String(format: mg == floor(mg) ? "%.0f" : "%.2f", mg)
                }
            }
            
            func setMcg(_ binding: inout String, from v: Double?) {
                if binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let v, v > 0 {
                    let mcg = v * 1_000_000
                    binding = String(format: mcg == floor(mcg) ? "%.0f" : "%.2f", mcg)
                }
            }

            func setG(_ binding: inout String, from v: Double?) {
                if binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let v, v > 0 {
                    binding = String(format: v == floor(v) ? "%.0f" : "%.2f", v)
                }
            }

            // Carb details
            setG(&sugars, from: resolved.sugars)
            setG(&fiber, from: resolved.fiber)
            
            // Fat details
            setG(&saturatedFat, from: resolved.saturatedFat)
            setG(&transFat, from: resolved.transFat)
            setG(&monounsaturatedFat, from: resolved.monounsaturatedFat)
            setG(&polyunsaturatedFat, from: resolved.polyunsaturatedFat)
            
            // Cholesterol & sodium
            setMg(&cholesterol, from: resolved.cholesterol)
            setMg(&sodium, from: resolved.sodium)
            setG(&salt, from: resolved.salt)
            
            // Major minerals
            setMg(&potassium, from: resolved.potassium)
            setMg(&calcium, from: resolved.calcium)
            setMg(&iron, from: resolved.iron)
            setMg(&magnesium, from: resolved.magnesium)
            setMg(&phosphorus, from: resolved.phosphorus)
            setMg(&zinc, from: resolved.zinc)
            
            // Trace minerals
            setMcg(&selenium, from: resolved.selenium)
            setMg(&copper, from: resolved.copper)
            setMg(&manganese, from: resolved.manganese)
            setMcg(&chromium, from: resolved.chromium)
            setMcg(&molybdenum, from: resolved.molybdenum)
            setMcg(&iodine, from: resolved.iodine)
            setMg(&chloride, from: resolved.chloride)
            
            // Vitamins
            setMcg(&vitaminA, from: resolved.vitaminA)
            setMg(&vitaminC, from: resolved.vitaminC)
            setMcg(&vitaminD, from: resolved.vitaminD)
            setMg(&vitaminE, from: resolved.vitaminE)
            setMcg(&vitaminK, from: resolved.vitaminK)
            
            // B Vitamins
            setMg(&thiamin, from: resolved.thiamin)
            setMg(&riboflavin, from: resolved.riboflavin)
            setMg(&niacin, from: resolved.niacin)
            setMg(&pantothenicAcid, from: resolved.pantothenicAcid)
            setMg(&vitaminB6, from: resolved.vitaminB6)
            setMcg(&biotin, from: resolved.biotin)
            setMcg(&folate, from: resolved.folate)
            setMcg(&vitaminB12, from: resolved.vitaminB12)
            
            // Other
            setMg(&choline, from: resolved.choline)

            // Fill macros if missing
            func macroSet(_ binding: inout String, from v: Double?) {
                if binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let v {
                    binding = String(format: v == floor(v) ? "%.0f" : "%.2f", v)
                }
            }
            macroSet(&protein, from: resolved.protein)
            macroSet(&carbs, from: resolved.carbs)
            macroSet(&fat, from: resolved.fat)
            if calories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                calories = String(resolved.calories)
            }
            if servingSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                servingSize = String(format: resolved.servingSize == floor(resolved.servingSize) ? "%.0f" : "%.1f", resolved.servingSize)
            }
            // Prefer OFF unit when ours is default g and prefill provided a different unit.
            if (servingUnitChoice == "g"),
               let u = prefill?.servingUnit, !u.isEmpty {
                if u == "g" || u == "ml" || u == "oz" {
                    servingUnitChoice = u
                } else {
                    servingUnitChoice = "Other"
                    customUnit = u
                }
            }
        } catch {
            // Silent fail; user can fill manually
        }
    }
}
