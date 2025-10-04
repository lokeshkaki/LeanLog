//
//  LogMealView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//  Updated: Simplified - Native keyboard + cleaner UI
//

import SwiftUI
import SwiftData
import UIKit

struct LogMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let meal: Meal

    @State private var portionGrams: Double = 100
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var logAsIndividualIngredients = false
    @State private var showIngredients = false

    @FocusState private var focusedField: Field?
    enum Field: Hashable { case none }

    // MARK: - Computed

    private var portionNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let n = meal.nutritionPer100g
        let f = max(0, portionGrams) / 100.0
        return (n.calories * f, n.protein * f, n.carbs * f, n.fat * f)
    }

    private var portionPercentage: Double {
        guard meal.totalYieldGrams > 0 else { return 0 }
        return (portionGrams / meal.totalYieldGrams) * 100
    }

    private var createdShort: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        if let created = meal.createdAt as Date? {
            return f.localizedString(for: created, relativeTo: Date())
        }
        return "—"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    mealInfoSection.modernCard(elevated: true)
                    portionCard.modernCard()
                    nutritionCard.modernCard()
                    logSettingsCard.modernCard()
                    logButton
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.top, AppTheme.Spacing.xl)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Log Meal")
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
    }

    // MARK: - Subviews

    private func metaChip(_ system: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.Colors.input)
        )
    }

    private var mealInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: "fork.knife")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 8) {
                        Text(meal.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                            .lineLimit(2)
                        if meal.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        metaChip("scalemass", "Yield: \(Int(meal.totalYieldGrams))g")
                        metaChip("clock", createdShort)
                    }
                }

                Spacer(minLength: 0)
            }

            if !meal.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showIngredients.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Ingredients")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                            Text("(\(meal.ingredients.count))")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Text(showIngredients ? "Hide" : "Show")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                    .rotationEffect(.degrees(showIngredients ? 180 : 0))
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.sm)
                    }
                    .buttonStyle(.plain)

                    if showIngredients {
                        VStack(spacing: 0) {
                            ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { idx, ing in
                                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(ing.name)
                                            .font(AppTheme.Typography.body.weight(.medium))
                                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                                        HStack(spacing: 8) {
                                            if let p = ing.protein, p > 0 {
                                                Text("P \(String(format: "%.1f", p * ing.quantity))g")
                                                    .font(AppTheme.Typography.caption2)
                                                    .foregroundStyle(AppTheme.Colors.protein)
                                            }
                                            if let c = ing.carbs, c > 0 {
                                                Text("C \(String(format: "%.1f", c * ing.quantity))g")
                                                    .font(AppTheme.Typography.caption2)
                                                    .foregroundStyle(AppTheme.Colors.carbs)
                                            }
                                            if let f = ing.fat, f > 0 {
                                                Text("F \(String(format: "%.1f", f * ing.quantity))g")
                                                    .font(AppTheme.Typography.caption2)
                                                    .foregroundStyle(AppTheme.Colors.fat)
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: AppTheme.Icons.calories)
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.Colors.calories)
                                            Text("\(Int(Double(ing.calories) * ing.quantity))")
                                                .font(AppTheme.Typography.subheadline.weight(.semibold))
                                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                                            Text("kcal")
                                                .font(AppTheme.Typography.caption2)
                                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                                        }
                                        Text("\(String(format: "%.2g", ing.quantity))× serving")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                                    }
                                }
                                .padding(.vertical, AppTheme.Spacing.sm)

                                if idx < meal.ingredients.count - 1 {
                                    Divider()
                                        .background(AppTheme.Colors.subtleStroke)
                                }
                            }
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var portionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Select portion")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            HStack(alignment: .firstTextBaseline) {
                Text("Weight")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                Spacer()
                Text("\(Int(portionGrams))g")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("That's \(String(format: "%.1f", portionPercentage))% of the total meal")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Slider(
                        value: $portionGrams,
                        in: 10...max(10, meal.totalYieldGrams),
                        step: 5
                    )
                    .tint(AppTheme.Colors.accent)
                    HStack {
                        Text("10g")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                        Spacer()
                        Text("\(Int(meal.totalYieldGrams))g")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Nutrition preview")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                Spacer()
                Text("For \(Int(portionGrams))g")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.Colors.input))
            }

            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    NutritionMiniCard(
                        icon: AppTheme.Icons.calories,
                        color: AppTheme.Colors.calories,
                        value: "\(Int(round(portionNutrition.calories)))",
                        unit: "kcal",
                        label: "Calories"
                    )
                    NutritionMiniCard(
                        icon: AppTheme.Icons.protein,
                        color: AppTheme.Colors.protein,
                        value: String(format: "%.1f", portionNutrition.protein),
                        unit: "g",
                        label: "Protein"
                    )
                }
                HStack(spacing: AppTheme.Spacing.md) {
                    NutritionMiniCard(
                        icon: AppTheme.Icons.carbs,
                        color: AppTheme.Colors.carbs,
                        value: String(format: "%.1f", portionNutrition.carbs),
                        unit: "g",
                        label: "Carbs"
                    )
                    NutritionMiniCard(
                        icon: AppTheme.Icons.fat,
                        color: AppTheme.Colors.fat,
                        value: String(format: "%.1f", portionNutrition.fat),
                        unit: "g",
                        label: "Fat"
                    )
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var logSettingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Log settings")
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

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Log as")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        logAsIndividualIngredients = false
                    } label: {
                        selectionRow(
                            icon: "square.stack",
                            title: "Meal",
                            subtitle: "1 food entry",
                            selected: !logAsIndividualIngredients
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        logAsIndividualIngredients = true
                    } label: {
                        selectionRow(
                            icon: "list.bullet",
                            title: "Ingredients",
                            subtitle: "\(meal.ingredients.count) separate food entries",
                            selected: logAsIndividualIngredients
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private func selectionRow(icon: String, title: String, subtitle: String, selected: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(selected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(selected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.accent)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selected ? AppTheme.Colors.accent.opacity(0.12) : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selected ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.subtleStroke,
                            lineWidth: 1
                        )
                }
        )
    }

    private var logButton: some View {
        Button(action: logMealPortion) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Log to Food Diary")
                    .font(AppTheme.Typography.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.accentGradient)
            )
        }
    }

    // MARK: - Actions

    private func logMealPortion() {
        let factor = max(0, portionGrams) / max(1, meal.totalYieldGrams)
        let ts = Date()

        if logAsIndividualIngredients {
            for ing in meal.ingredients {
                let cals = Int(round(Double(ing.calories) * ing.quantity * factor))
                let p = (ing.protein ?? 0) * ing.quantity * factor
                let c = (ing.carbs ?? 0) * ing.quantity * factor
                let f = (ing.fat ?? 0) * ing.quantity * factor

                let entry = FoodEntry(
                    name: ing.name,
                    calories: cals,
                    protein: p > 0 ? p : nil,
                    carbs: c > 0 ? c : nil,
                    fat: f > 0 ? f : nil,
                    servingSize: ing.servingSize,
                    servingUnit: ing.servingUnit,
                    date: selectedDate,
                    timestamp: ts,
                    source: "Meal: \(meal.name)",
                    externalId: nil
                )
                modelContext.insert(entry)
            }
        } else {
            let n = portionNutrition
            let entry = FoodEntry(
                name: meal.name,
                calories: Int(round(n.calories)),
                protein: n.protein,
                carbs: n.carbs,
                fat: n.fat,
                servingSize: portionGrams,
                servingUnit: "g",
                date: selectedDate,
                timestamp: ts,
                source: "Meal",
                externalId: nil
            )
            modelContext.insert(entry)
        }

        meal.lastUsedAt = Date()
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("Error logging meal portion: \(error)")
        }
    }
}
