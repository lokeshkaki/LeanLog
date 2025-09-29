//
//  AddFoodView.swift
//  LeanLog
//
//  Native keyboard toolbar + QuickType + optional transparent accessory background
//

import SwiftUI
import SwiftData
import UIKit

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let defaultDate: Date

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = ""
    @State private var selectedDate: Date

    @FocusState private var focusedField: Field?

    // Toggle this to turn the transparency tweak on/off (recommended: keep true in dev, evaluate in prod).
    private let makeKeyboardBarTransparent = true

    // Locale-aware number IO
    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    enum Field: CaseIterable, Hashable {
        case name, servingSize, servingUnit, calories, protein, carbs, fat
    }

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        self._selectedDate = State(initialValue: Calendar.current.startOfDay(for: defaultDate))
    }

    private var orderedFields: [Field] { [.name, .servingSize, .servingUnit, .calories, .protein, .carbs, .fat] }
    private var focusedIndex: Int? { focusedField.flatMap { orderedFields.firstIndex(of: $0) } }
    private var canGoPrev: Bool { (focusedIndex ?? 0) > 0 }
    private var canGoNext: Bool { (focusedIndex ?? (orderedFields.count - 1)) < orderedFields.count - 1 }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                        headerCard.modernCard(elevated: true)
                        nameServingCard.modernCard()
                        macrosGridCard.modernCard()
                        logDetailsCard.modernCard()
                        if shouldShowCalculatedValues { calculatedValuesCard.modernCard(elevated: true) }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                }
                .onChange(of: focusedField) { _ in scrollFocusedIntoView(proxy) }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    scrollFocusedIntoView(proxy)
                    if makeKeyboardBarTransparent { KeyboardAccessoryStyler.shared.makeTransparent() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)) { _ in
                    if makeKeyboardBarTransparent { KeyboardAccessoryStyler.shared.makeTransparent() }
                }
            }
            .screenBackground()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)

            .toolbar {
                // Native Apple keyboard toolbar (keeps the liquid glass buttons)
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField != nil {
                        Button(action: previousField) {
                            Image(systemName: "chevron.up").imageScale(.medium)
                        }
                        .disabled(!canGoPrev)

                        Button(action: nextField) {
                            Image(systemName: "chevron.down").imageScale(.medium)
                        }
                        .disabled(!canGoNext)

                        Spacer()

                        Button(action: { focusedField = nil }) {
                            Image(systemName: "checkmark")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Done editing")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close).imageScale(.medium)
                    }
                    .accessibilityLabel("Cancel")
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
                Text("Create a new entry").font(AppTheme.Typography.title3).foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("Enter food details, macros, and date.").font(AppTheme.Typography.subheadline).foregroundStyle(AppTheme.Colors.labelSecondary)
            }
            Spacer()
        }
    }

    private var nameServingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Food details").font(AppTheme.Typography.headline).foregroundStyle(AppTheme.Colors.labelPrimary)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "text.cursor").foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Food name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)   // allow QuickType
                        .keyboardType(.default)          // text-capable keyboard
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
                    Text("Name is required.").font(AppTheme.Typography.caption).foregroundStyle(AppTheme.Colors.labelTertiary)
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
                        .onChange(of: servingSize) { servingSize = numberIO.sanitizeDecimal(servingSize) }
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
            Text("Nutrition (per serving)").font(AppTheme.Typography.headline).foregroundStyle(AppTheme.Colors.labelPrimary)

            let columns = [GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
                           GridItem(.flexible(), spacing: AppTheme.Spacing.lg)]

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                macroField(icon: AppTheme.Icons.calories, title: "Calories", unit: "kcal", color: AppTheme.Colors.calories, text: $calories, field: .calories, keyboard: .numberPad, sanitizer: { numberIO.sanitizeInteger($0) })
                    .id(Field.calories)
                macroField(icon: AppTheme.Icons.protein,  title: "Protein",  unit: "g",    color: AppTheme.Colors.protein,  text: $protein,  field: .protein,  keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
                    .id(Field.protein)
                macroField(icon: AppTheme.Icons.carbs,    title: "Carbs",    unit: "g",    color: AppTheme.Colors.carbs,    text: $carbs,    field: .carbs,    keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
                    .id(Field.carbs)
                macroField(icon: AppTheme.Icons.fat,      title: "Fat",      unit: "g",    color: AppTheme.Colors.fat,      text: $fat,      field: .fat,      keyboard: .decimalPad, sanitizer: { numberIO.sanitizeDecimal($0) })
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
                    .onChange(of: text.wrappedValue) { newValue in
                        let sanitized = sanitizer(newValue)
                        if sanitized != newValue {
                            text.wrappedValue = sanitized
                        }
                    }

                Text(unit).font(AppTheme.Typography.callout).foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            .modernField(focused: focusedField == field)
        }
    }

    private var logDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Log details").font(AppTheme.Typography.headline).foregroundStyle(AppTheme.Colors.labelPrimary)
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
                    Text("Mismatch detected with entered calories.").font(AppTheme.Typography.caption).foregroundStyle(AppTheme.Colors.warning)
                    Spacer()
                    Button {
                        calories = "\(macroCals)"
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Use 4–4–9")
                            .font(AppTheme.Typography.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
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

    private func nextField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        focusedField = orderedFields[min(idx + 1, orderedFields.count - 1)]
    }

    private func previousField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        focusedField = orderedFields[max(idx - 1, 0)]
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
            source: "Manual",
            externalId: nil
        )

        modelContext.insert(entry)

        // Rely on SwiftData autosave
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    // MARK: - Scrolling helper

    private func scrollFocusedIntoView(_ proxy: ScrollViewProxy) {
        guard let field = focusedField else { return }
        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .bottom) }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .bottom) }
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

    private var decimalSeparator: String {
        formatter.decimalSeparator ?? "."
    }

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
