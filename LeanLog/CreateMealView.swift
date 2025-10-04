//
//  CreateMealView.swift
//  LeanLog
//
//  Simplified: Native keyboard + tap-to-dismiss
//

import SwiftUI
import SwiftData
import UIKit

struct CreateMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var mealName = ""
    @State private var totalYieldGrams = ""
    @State private var ingredients: [MealIngredient] = []
    @State private var showingAddIngredient = false

    @FocusState private var focusedField: Field?
    enum Field: Hashable { case mealName, totalYield }

    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    private var isValid: Bool {
        !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(totalYieldGrams) ?? 0 > 0 &&
        !ingredients.isEmpty
    }

    private var orderedFields: [Field] {
        [.mealName, .totalYield]
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                        mealNameCard.modernCard()
                        ingredientsCard.modernCard()
                        if !ingredients.isEmpty {
                            nutritionCard.modernCard(elevated: true)
                            totalYieldCard.modernCard()
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
                .onChange(of: focusedField) { _ in
                    scrollFocusedIntoView(proxy)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create Meal")
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveMeal) {
                        Image(systemName: AppTheme.Icons.save)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.4)
                    .accessibilityLabel("Save")
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView { ingredient in
                    ingredients.append(ingredient)
                }
            }
        }
    }

    // MARK: - Cards

    private var mealNameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Meal name")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                TextField("e.g., Chicken Rice Bowl", text: $mealName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .keyboardType(.default)
                    .focused($focusedField, equals: .mealName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .totalYield }
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
            }
            .modernField(focused: focusedField == .mealName)
            .id(Field.mealName)
        }
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            HStack {
                Text("Ingredients")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                if !ingredients.isEmpty {
                    Text("(\(ingredients.count))")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                Spacer()
                Button {
                    showingAddIngredient = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: AppTheme.Icons.add)
                        Text("Add")
                            .font(AppTheme.Typography.bodyEmphasized)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(AppTheme.Colors.accentGradient)
                    .clipShape(Capsule())
                }
            }

            if ingredients.isEmpty {
                Text("Add ingredients to calculate nutrition and yield.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        IngredientRowCard(
                            ingredient: ingredient,
                            onDelete: { ingredients.remove(at: index) }
                        )
                    }
                }
            }
        }
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            HStack {
                Text("Nutrition preview")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Spacer()
                Text("Total")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.Colors.input))
            }

            let totals = totalsForMeal()

            VStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    NutritionMiniCard(
                        icon: AppTheme.Icons.calories,
                        color: AppTheme.Colors.calories,
                        value: "\(Int(round(totals.calories)))",
                        unit: "kcal",
                        label: "Calories"
                    )
                    NutritionMiniCard(
                        icon: AppTheme.Icons.protein,
                        color: AppTheme.Colors.protein,
                        value: String(format: "%.1f", totals.protein),
                        unit: "g",
                        label: "Protein"
                    )
                }
                HStack(spacing: AppTheme.Spacing.lg) {
                    NutritionMiniCard(
                        icon: AppTheme.Icons.carbs,
                        color: AppTheme.Colors.carbs,
                        value: String(format: "%.1f", totals.carbs),
                        unit: "g",
                        label: "Carbs"
                    )
                    NutritionMiniCard(
                        icon: AppTheme.Icons.fat,
                        color: AppTheme.Colors.fat,
                        value: String(format: "%.1f", totals.fat),
                        unit: "g",
                        label: "Fat"
                    )
                }
            }
        }
    }

    private var totalYieldCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Total yield")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "scalemass")
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Enter weight", text: $totalYieldGrams)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .totalYield)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .onChange(of: totalYieldGrams) { newValue in
                            totalYieldGrams = numberIO.sanitizeDecimal(newValue)
                        }
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .totalYield)
                .id(Field.totalYield)

                Text("grams")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
            }
        }
    }

    // MARK: - Actions

    private func totalsForMeal() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let calories = ingredients.reduce(0.0) { $0 + Double($1.calories) * $1.quantity }
        let protein  = ingredients.reduce(0.0) { $0 + ($1.protein ?? 0) * $1.quantity }
        let carbs    = ingredients.reduce(0.0) { $0 + ($1.carbs ?? 0) * $1.quantity }
        let fat      = ingredients.reduce(0.0) { $0 + ($1.fat ?? 0) * $1.quantity }
        return (calories, protein, carbs, fat)
    }

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

    private func saveMeal() {
        guard isValid, let yield = Double(totalYieldGrams) else { return }
        let meal = Meal(
            name: mealName.trimmingCharacters(in: .whitespacesAndNewlines),
            totalYieldGrams: yield
        )
        for ing in ingredients {
            ing.meal = meal
            meal.ingredients.append(ing)
        }
        modelContext.insert(meal)
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error saving meal: \(error)")
        }
    }
}

// MARK: - Supporting Views

private struct IngredientRowCard: View {
    let ingredient: MealIngredient
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("\(String(format: "%.2g", ingredient.quantity))× serving")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: AppTheme.Icons.delete)
                    .imageScale(.small)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.destructive)
            .controlSize(.mini)
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
