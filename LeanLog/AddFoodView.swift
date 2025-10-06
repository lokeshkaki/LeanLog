//
//  AddFoodView.swift
//  LeanLog
//
//  Simplified: Native keyboard + tap-to-dismiss
//  Updated: Supports Prefill so scanned foods can be edited before saving.
//

import SwiftUI
import SwiftData
import UIKit

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let defaultDate: Date

    // NEW: optional prefill for scanned items (or other sources)
    struct Prefill: Sendable {
        let name: String?
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let servingSize: Double?
        let servingUnit: String?
        let source: String?           // e.g., "OFF", "USDA"
        let externalId: String?       // e.g., barcode
    }

    private let prefill: Prefill?

    // Fields
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = ""
    @State private var selectedDate: Date

    @FocusState private var focusedField: Field?

    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    enum Field: CaseIterable, Hashable {
        case name, servingSize, servingUnit, calories, protein, carbs, fat
    }

    init(defaultDate: Date, prefill: Prefill? = nil) {
        self.defaultDate = defaultDate
        self.prefill = prefill
        let sod = Calendar.current.startOfDay(for: defaultDate)
        self._selectedDate = State(initialValue: sod)

        // Seed states from prefill (stringify with reasonable precision)
        let fmt2: (Double?) -> String = { v in
            guard let v = v else { return "" }
            if v == floor(v) { return String(Int(v)) }
            return String(format: "%.2f", v)
        }
        self._name = State(initialValue: prefill?.name ?? "")
        self._calories = State(initialValue: prefill?.calories.map { String($0) } ?? "")
        self._protein = State(initialValue: fmt2(prefill?.protein))
        self._carbs = State(initialValue: fmt2(prefill?.carbs))
        self._fat = State(initialValue: fmt2(prefill?.fat))
        self._servingSize = State(initialValue: fmt2(prefill?.servingSize))
        self._servingUnit = State(initialValue: prefill?.servingUnit ?? "")
    }

    private var orderedFields: [Field] {
        [.name, .servingSize, .servingUnit, .calories, .protein, .carbs, .fat]
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                        headerCard.modernCard(elevated: true)
                        nameServingCard.modernCard()
                        macrosGridCard.modernCard()
                        logDetailsCard.modernCard()
                        if shouldShowCalculatedValues {
                            calculatedValuesCard.modernCard(elevated: true)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                }
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
                .onChange(of: focusedField) { _ in scrollFocusedIntoView(proxy) }
            }
            .screenBackground()
            .navigationTitle(prefill == nil ? "Add Food" : "Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
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
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle().fill(AppTheme.Colors.accentGradient).frame(width: 48, height: 48)
                Image(systemName: "fork.knife.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .font(.system(size: 22, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(prefill == nil ? "Create a new entry" : "Review and edit")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("Adjust name, serving, calories, and macros, then save.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
            }
            Spacer()
        }
    }

    private var nameServingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Food details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "text.cursor").foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Food name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .keyboardType(.default)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .servingSize }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    if !name.isEmpty {
                        Button { name = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.Colors.labelTertiary)
                        }
                        .accessibilityLabel("Clear name")
                    }
                }
                .modernField(focused: focusedField == .name)
                .id(Field.name)

                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Name is required.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                }
            }

            // Serving
            HStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    Image(systemName: "scale.3d").foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Serving size", text: $servingSize)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .servingSize)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .servingUnit }
                        .onChange(of: servingSize) { servingSize = numberIO.sanitizeDecimal($0) }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .servingSize)
                .id(Field.servingSize)

                HStack {
                    Image(systemName: "ruler").foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Unit (e.g., g, oz)", text: $servingUnit)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .servingUnit)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .calories }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .servingUnit)
                .id(Field.servingUnit)
            }
        }
    }

    private var macrosGridCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Nutrition (per serving)")
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

            if calories.isEmpty && (!protein.isEmpty || !carbs.isEmpty || !fat.isEmpty) {
                Text("Calories recommended for accurate logging.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
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
                TextField("0", text: text)
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: field)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .submitLabel(field == .fat ? .done : .next)
                    .onSubmit { field == .fat ? (focusedField = nil) : advanceFrom(field) }
                    .onChange(of: text.wrappedValue) {
                        let sanitized = sanitizer($0)
                        if sanitized != $0 { text.wrappedValue = sanitized }
                    }
                Text(unit).font(AppTheme.Typography.callout).foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            .modernField(focused: focusedField == field)
        }
    }

    private var logDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Log details")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            HStack {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: AppTheme.Icons.calendar).foregroundStyle(AppTheme.Colors.accent).frame(width: 24)
                    Text("Date").font(AppTheme.Typography.body).foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                Spacer()
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.Colors.input)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .strokeBorder(AppTheme.Colors.subtleStroke, lineWidth: 1)
                    }
            )
        }
    }

    private var calculatedValuesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: AppTheme.Icons.function).foregroundStyle(AppTheme.Colors.labelSecondary)
                Text("Calculated values").font(AppTheme.Typography.headline).foregroundStyle(AppTheme.Colors.labelPrimary)
                Spacer()
            }
            let macroCals = calculateMacroCalories()
            let enteredCals = Int(calories) ?? 0
            let mismatch = abs(macroCals - enteredCals) > 10 && enteredCals > 0
            HStack {
                Text("Calories from macros").font(AppTheme.Typography.callout).foregroundStyle(AppTheme.Colors.labelSecondary)
                Spacer()
                Text("\(macroCals) kcal")
                    .font(AppTheme.Typography.callout).fontWeight(.semibold)
                    .foregroundStyle(mismatch ? AppTheme.Colors.warning : AppTheme.Colors.labelPrimary)
            }
            if mismatch {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: AppTheme.Icons.warning).foregroundStyle(AppTheme.Colors.warning)
                    Text("Mismatch detected with entered calories.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.warning)
                    Spacer()
                    Button {
                        calories = "\(macroCals)"
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Use 4–4–9")
                            .font(AppTheme.Typography.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(AppTheme.Colors.accentGradient))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Validation & Focus

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !calories.isEmpty
    }

    private var shouldShowCalculatedValues: Bool {
        !calories.isEmpty || !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty
    }

    private func advanceFrom(_ field: Field) {
        guard let idx = orderedFields.firstIndex(of: field) else { return }
        focusedField = idx < orderedFields.count - 1 ? orderedFields[idx + 1] : nil
    }

    private func calculateMacroCalories() -> Int {
        let p = numberIO.parseDecimal(protein) ?? 0
        let c = numberIO.parseDecimal(carbs) ?? 0
        let f = numberIO.parseDecimal(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }

    private func saveFood() {
        guard isValid else { return }

        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Int(calories) ?? 0,
            protein: numberIO.parseDecimal(protein),
            carbs: numberIO.parseDecimal(carbs),
            fat: numberIO.parseDecimal(fat),
            servingSize: servingSize.isEmpty ? nil : numberIO.parseDecimal(servingSize),
            servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Calendar.current.startOfDay(for: selectedDate),
            timestamp: Date(),
            source: prefill?.source ?? "Manual",
            externalId: prefill?.externalId
        )

        modelContext.insert(entry)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    // MARK: - Scrolling helper

    private func scrollFocusedIntoView(_ proxy: ScrollViewProxy) {
        guard let field = focusedField else { return }
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

// MARK: - Locale-aware number IO helper

private struct LocalizedNumberIO {
    private let formatter: NumberFormatter

    init(maxFractionDigits: Int = 2, locale: Locale = .current) {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = maxFractionDigits
        nf.usesGroupingSeparator = false
        self.formatter = nf
    }

    private var decimalSeparator: String { formatter.decimalSeparator ?? "." }

    func parseDecimal(_ s: String) -> Double? {
        guard !s.isEmpty else { return nil }
        return formatter.number(from: s)?.doubleValue
    }

    func sanitizeDecimal(_ s: String) -> String {
        guard !s.isEmpty else { return s }
        let sep = decimalSeparator
        var out = ""
        var seenSep = false
        for ch in s {
            if ch.isNumber {
                out.append(ch)
            } else if String(ch) == sep, !seenSep {
                out.append(ch)
                seenSep = true
            }
        }
        if out.hasPrefix(sep) { out = "0" + out }
        if let range = out.range(of: sep) {
            let fractional = out[range.upperBound...]
            if fractional.count > formatter.maximumFractionDigits {
                let allowed = fractional.prefix(formatter.maximumFractionDigits)
                out = String(out[..<range.upperBound]) + allowed
            }
        }
        return out
    }

    func sanitizeInteger(_ s: String) -> String {
        s.filter { $0.isNumber }
    }
}
