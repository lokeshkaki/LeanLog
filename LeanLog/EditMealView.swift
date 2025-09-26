//
//  EditMealView.swift
//  LeanLog
//
//  Updated: System keyboard toolbar “Done” (no hidden chip), compact top bar, tight paddings identical to Create/Log
//

import SwiftUI
import SwiftData

struct EditMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var meal: Meal

    @State private var name: String
    @State private var totalYieldGrams: String
    @State private var ingredients: [MealIngredient]
    @State private var showingAddIngredient = false
    @State private var pendingDelete = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, yield }

    init(meal: Meal) {
        self.meal = meal
        _name = State(initialValue: meal.name)
        _totalYieldGrams = State(initialValue: String(Int(meal.totalYieldGrams)))
        _ingredients = State(initialValue: meal.ingredients)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Double(totalYieldGrams) ?? 0) > 0 &&
        !ingredients.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    nameCard.modernCard()
                    ingredientsCard.modernCard()
                    if !ingredients.isEmpty {
                        nutritionCard.modernCard(elevated: true)
                        yieldCard.modernCard()
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.xl)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Meal")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close).imageScale(.medium)
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { pendingDelete = true } label: {
                        Image(systemName: AppTheme.Icons.delete).imageScale(.medium)
                    }
                    .tint(AppTheme.Colors.destructive)
                    .accessibilityLabel("Delete meal")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Image(systemName: AppTheme.Icons.save)
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.medium)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.4)
                    .accessibilityLabel("Save")
                }
                // System keyboard toolbar — always above keyboard on all devices
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                        .buttonBorderShape(.capsule)
                        .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView { ing in ingredients.append(ing) }
            }
            .alert("Delete Meal", isPresented: $pendingDelete) {
                Button("Delete", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove the meal and its ingredients reference.")
            }
        }
    }

    // MARK: - Cards (tight density)

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Meal name")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "text.cursor").foregroundStyle(AppTheme.Colors.labelTertiary)
                TextField("e.g., Chicken Rice Bowl", text: $name)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .name)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
            }
            .modernField(focused: focusedField == .name)
        }
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            HStack {
                Text("Ingredients")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("(\(ingredients.count))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                Spacer()
                Button { showingAddIngredient = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: AppTheme.Icons.add)
                        Text("Add").font(AppTheme.Typography.bodyEmphasized)
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
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { idx, ing in
                        IngredientRowCard(
                            ingredient: ing,
                            onDelete: { ingredients.remove(at: idx) }
                        )
                    }
                }
            }
        }
    }

    private var nutritionCard: some View {
        let totals = totalsForIngredients()
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
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
            VStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    NutritionMiniCard(icon: AppTheme.Icons.calories, color: AppTheme.Colors.calories, value: "\(Int(round(totals.calories)))", unit: "kcal", label: "Calories")
                    NutritionMiniCard(icon: AppTheme.Icons.protein, color: AppTheme.Colors.protein, value: String(format: "%.1f", totals.protein), unit: "g", label: "Protein")
                }
                HStack(spacing: AppTheme.Spacing.lg) {
                    NutritionMiniCard(icon: AppTheme.Icons.carbs, color: AppTheme.Colors.carbs, value: String(format: "%.1f", totals.carbs), unit: "g", label: "Carbs")
                    NutritionMiniCard(icon: AppTheme.Icons.fat,   color: AppTheme.Colors.fat,   value: String(format: "%.1f", totals.fat),   unit: "g", label: "Fat")
                }
            }
        }
    }

    private var yieldCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.rowSpacing) {
            Text("Total yield")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "scalemass").foregroundStyle(AppTheme.Colors.labelTertiary)
                    TextField("Enter weight", text: $totalYieldGrams)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .yield)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                .modernField(focused: focusedField == .yield)

                Text("grams")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func totalsForIngredients() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let calories = ingredients.reduce(0.0) { $0 + Double($1.calories) * $1.quantity }
        let protein  = ingredients.reduce(0.0) { $0 + ($1.protein ?? 0) * $1.quantity }
        let carbs    = ingredients.reduce(0.0) { $0 + ($1.carbs ?? 0) * $1.quantity }
        let fat      = ingredients.reduce(0.0) { $0 + ($1.fat ?? 0) * $1.quantity }
        return (calories, protein, carbs, fat)
    }

    private func save() {
        guard isValid else { return }
        meal.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        meal.totalYieldGrams = Double(totalYieldGrams) ?? meal.totalYieldGrams
        meal.ingredients = ingredients
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error saving meal: \(error)")
        }
    }

    private func delete() {
        modelContext.delete(meal)
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error deleting meal: \(error)")
        }
    }
}

// Same density as CreateMeal
private struct IngredientRowCard: View {
    let ingredient: MealIngredient
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(AppTheme.Typography.body.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Text("\(String(format: "%.2g", ingredient.quantity))× serving")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: AppTheme.Icons.delete).imageScale(.small)
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
