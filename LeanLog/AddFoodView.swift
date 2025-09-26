//
//  AddFoodView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Custom clear keyboard accessory bar + AnyShapeStyle fix for background fill
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

    enum Field: CaseIterable {
        case name, servingSize, servingUnit, calories, protein, carbs, fat
    }

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        self._selectedDate = State(initialValue: Calendar.current.startOfDay(for: defaultDate))
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
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardAccessory(focusedField: binding($focusedField), equals: .name,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .servingSize,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .servingUnit,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .calories,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .protein,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .carbs,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .keyboardAccessory(focusedField: binding($focusedField), equals: .fat,
                config: .init(showPrevious: true, showNext: true,
                    onPrevious: { previousField() },
                    onNext: { nextField() },
                    onDone: { focusedField = nil }))
            .tint(AppTheme.Colors.accent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close)
                            .imageScale(.medium)
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveFood) {
                        Image(systemName: AppTheme.Icons.save)
                            .symbolRenderingMode(.hierarchical)
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
        HStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGradient)
                    .frame(width: 48, height: 48)
                Image(systemName: "fork.knife.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .font(.system(size: 22, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Create a new entry")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("Enter food details, macros, and date.")
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

    private func calculateMacroCalories() -> Int {
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }

    private func saveFood() {
        guard isValid else { return }

        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            servingSize: servingSize.isEmpty ? nil : Double(servingSize),
            servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Calendar.current.startOfDay(for: selectedDate),
            timestamp: Date(),
            source: "Manual",
            externalId: nil
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error saving food entry: \(error)")
        }
    }
}
