//
//  EditFoodView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Move Delete to trailing toolbar as icon-only with confirmation; remove Danger card
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

    enum Field: CaseIterable {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    headerCard
                        .modernCard(elevated: true)

                    nameServingCard
                        .modernCard()

                    macrosGridCard
                        .modernCard()

                    logDetailsCard
                        .modernCard()

                    if shouldShowCalculatedValues {
                        calculatedValuesCard
                            .modernCard(elevated: true)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.xl)
            }
            .screenBackground()
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .name,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .servingSize,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .servingUnit,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .calories,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .protein,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .carbs,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .keyboardAccessory(
                focusedField: binding($focusedField),
                equals: .fat,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil })
            )
            .tint(AppTheme.Colors.accent)
            .toolbar {
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
                        .disableAutocorrection(true)
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
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .servingSize)

                HStack {
                    Image(systemName: "ruler")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Unit (e.g., g, oz)", text: $servingUnit)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .servingUnit)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .calories }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .servingUnit)
            }

            // Source (read-only)
            if let source = entry.source, !source.isEmpty {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    Text("Source")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                    Spacer()
                    Text(source)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
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
                macroField(icon: AppTheme.Icons.calories, title: "Calories", unit: "kcal", color: AppTheme.Colors.calories, text: $calories, field: .calories, keyboard: .numberPad)
                macroField(icon: AppTheme.Icons.protein,  title: "Protein",  unit: "g",    color: AppTheme.Colors.protein,  text: $protein,  field: .protein,  keyboard: .decimalPad)
                macroField(icon: AppTheme.Icons.carbs,    title: "Carbs",    unit: "g",    color: AppTheme.Colors.carbs,    text: $carbs,    field: .carbs,    keyboard: .decimalPad)
                macroField(icon: AppTheme.Icons.fat,      title: "Fat",      unit: "g",    color: AppTheme.Colors.fat,      text: $fat,      field: .fat,      keyboard: .decimalPad)
            }

            if calories.isEmpty && (!protein.isEmpty || !carbs.isEmpty || !fat.isEmpty) {
                Text("Calories recommended for accurate logging.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            }
        }
    }

    private func macroField(icon: String, title: String, unit: String, color: Color, text: Binding<String>, field: Field, keyboard: UIKeyboardType) -> some View {
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
                    .submitLabel(.next)
                    .onSubmit { advanceFrom(field) }

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
                            .strokeBorder(AppTheme.Colors.subtleStroke, lineWidth: 1)
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

            let macroCals = calculateCaloriesFromMacros()
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

    // MARK: - Computed

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !calories.isEmpty
    }

    private var shouldShowCalculatedValues: Bool {
        !calories.isEmpty || !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty
    }

    private var orderedFields: [Field] {
        [.name, .servingSize, .servingUnit, .calories, .protein, .carbs, .fat]
    }

    // MARK: - Helpers

    private func advanceFrom(_ field: Field) {
        if let idx = orderedFields.firstIndex(of: field), idx < orderedFields.endIndex - 1 {
            focusedField = orderedFields[idx + 1]
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

    private func calculateCaloriesFromMacros() -> Int {
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }

    private func saveChanges() {
        guard isValid else { return }

        entry.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.calories = Int(calories) ?? 0
        entry.protein = protein.isEmpty ? 0 : (Double(protein) ?? 0)
        entry.carbs = carbs.isEmpty ? 0 : (Double(carbs) ?? 0)
        entry.fat = fat.isEmpty ? 0 : (Double(fat) ?? 0)
        entry.servingSize = servingSize.isEmpty ? nil : Double(servingSize)
        entry.servingUnit = servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.date = Calendar.current.startOfDay(for: selectedDate)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error saving changes: \(error)")
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
