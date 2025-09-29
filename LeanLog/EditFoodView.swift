//
//  EditFoodView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Native keyboard toolbar (Prev/Next/checkmark) + QuickType + transparent accessory
//

import SwiftUI
import SwiftData
import UIKit

struct EditFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: FoodEntry

    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var servingSize: String
    @State private var servingUnit: String
    @State private var selectedDate: Date
    @State private var showingDeleteAlert = false

    @FocusState private var focusedField: Field?

    // Locale-aware number IO
    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    enum Field: CaseIterable, Hashable {
        case name, servingSize, servingUnit, calories, protein, carbs, fat
    }

    init(entry: FoodEntry) {
        self.entry = entry

        _name = State(initialValue: entry.name)
        _calories = State(initialValue: String(entry.calories))

        let p = entry.protein ?? 0
        let c = entry.carbs ?? 0
        let f = entry.fat ?? 0

        _protein = State(initialValue: p > 0 ? String(format: "%.1f", p).replacingOccurrences(of: ".0", with: "") : "")
        _carbs   = State(initialValue: c > 0 ? String(format: "%.1f", c).replacingOccurrences(of: ".0", with: "") : "")
        _fat     = State(initialValue: f > 0 ? String(format: "%.1f", f).replacingOccurrences(of: ".0", with: "") : "")

        if let size = entry.servingSize {
            _servingSize = State(initialValue: String(format: "%.1f", size).replacingOccurrences(of: ".0", with: ""))
        } else {
            _servingSize = State(initialValue: "")
        }
        _servingUnit = State(initialValue: entry.servingUnit ?? "")
        _selectedDate = State(initialValue: entry.date)
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

                        if shouldShowCalculatedValues {
                            calculatedValuesCard.modernCard(elevated: true)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                }
                // Keep focused field visible and apply transparent styling
                .onChange(of: focusedField) { _ in scrollFocusedIntoView(proxy) }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    scrollFocusedIntoView(proxy)
                    KeyboardAccessoryStyler.shared.makeTransparent()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)) { _ in
                    KeyboardAccessoryStyler.shared.makeTransparent()
                }
            }
            .screenBackground()
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                // Keyboard toolbar: Prev / Next / checkmark (no cutoff issues)
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField != nil {
                        Button(action: previousField) {
                            Image(systemName: "chevron.up").imageScale(.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canGoPrev)
                        .accessibilityLabel("Previous field")

                        Button(action: nextField) {
                            Image(systemName: "chevron.down").imageScale(.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canGoNext)
                        .accessibilityLabel("Next field")

                        Spacer()

                        Button(action: { focusedField = nil }) {
                            Image(systemName: "checkmark")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Done editing")
                    }
                }

                // Leading: Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close)
                            .imageScale(.medium)
                    }
                    .accessibilityLabel("Cancel")
                }

                // Trailing: Delete (icon-only), then Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Image(systemName: AppTheme.Icons.delete)
                            .imageScale(.medium)
                            .foregroundStyle(AppTheme.Colors.destructive)
                    }
                    .accessibilityLabel("Delete entry")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveChanges) {
                        Image(systemName: AppTheme.Icons.save)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.4)
                    .accessibilityLabel("Save")
                }
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this food entry? This action cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGradient)
                    .frame(width: 48, height: 48)
                Image(systemName: "pencil")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .font(.system(size: 22, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Update this entry")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("Edit details, macros, and date.")
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
                    Image(systemName: "text.cursor")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Food name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)   // Keep QuickType for name
                        .keyboardType(.default)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .servingSize }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    if !name.isEmpty {
                        Button {
                            name = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.Colors.labelTertiary)
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
                    Image(systemName: "scale.3d")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
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
                    Image(systemName: "ruler")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
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

            let columns: [GridItem] = [
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
                GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
            ]

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

    private func macroField(icon: String, title: String, unit: String, color: Color, text: Binding<String>, field: Field, keyboard: UIKeyboardType, sanitizer: @escaping (String) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 22)
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
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

                Text(unit)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
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
                    Image(systemName: AppTheme.Icons.calendar)
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(width: 24)
                    Text("Date")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
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
                            .stroke(AppTheme.Colors.subtleStroke, lineWidth: 1)
                    }
            )
        }
    }

    private var calculatedValuesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: AppTheme.Icons.function)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                Text("Calculated values")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Spacer()
            }

            let macroCals = calculateMacroCalories()
            let enteredCals = Int(calories) ?? 0
            let mismatch = abs(macroCals - enteredCals) > 10 && enteredCals > 0

            HStack {
                Text("Calories from macros")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                Spacer()
                Text("\(macroCals) kcal")
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(mismatch ? AppTheme.Colors.warning : AppTheme.Colors.labelPrimary)
            }

            if mismatch {
                HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: AppTheme.Icons.warning)
                        .foregroundStyle(AppTheme.Colors.warning)
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

    // MARK: - Validation
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !calories.isEmpty
    }

    private var shouldShowCalculatedValues: Bool {
        !calories.isEmpty || !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty
    }

    // MARK: - Focus helpers
    private func advanceFrom(_ field: Field) {
        let all = orderedFields
        if let idx = all.firstIndex(of: field), idx < all.endIndex - 1 {
            focusedField = all[idx + 1]
        } else {
            focusedField = nil
        }
    }

    private func nextField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        let nextIdx = min(idx + 1, orderedFields.count - 1)
        focusedField = orderedFields[nextIdx]
    }

    private func previousField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        let prevIdx = max(idx - 1, 0)
        focusedField = orderedFields[prevIdx]
    }

    private func scrollFocusedIntoView(_ proxy: ScrollViewProxy) {
        guard let field = focusedField else { return }
        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .bottom) }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .bottom) }
        }
    }

    // MARK: - Logic
    private func calculateMacroCalories() -> Int {
        let p = numberIO.parseDecimal(protein) ?? 0
        let c = numberIO.parseDecimal(carbs) ?? 0
        let f = numberIO.parseDecimal(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }

    private func saveChanges() {
        guard isValid else { return }

        entry.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.calories = Int(calories) ?? 0
        entry.protein = protein.isEmpty ? nil : numberIO.parseDecimal(protein)
        entry.carbs = carbs.isEmpty ? nil : numberIO.parseDecimal(carbs)
        entry.fat = fat.isEmpty ? nil : numberIO.parseDecimal(fat)
        entry.servingSize = servingSize.isEmpty ? nil : numberIO.parseDecimal(servingSize)
        entry.servingUnit = servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.date = Calendar.current.startOfDay(for: selectedDate)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error saving entry: \(error)")
        }
    }

    private func deleteEntry() {
        modelContext.delete(entry)
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error deleting entry: \(error)")
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
