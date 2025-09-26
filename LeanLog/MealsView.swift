//
//  MealsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//  Updated: Themed cards, predicate-based querying, consistent toolbar, modern empty state
//           Unified keyboard accessory for search (clear Done bar)
//           Added Edit Meal entry points (swipe, context menu, and sheet)
//

import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingCreateMeal = false
    @State private var showingLogMeal: Meal? = nil
    @State private var showingEditMeal: Meal? = nil
    @FocusState private var searchFocused: Bool?   // optional Bool focus

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    // Search field sits under the title for symmetry with Home
                    SearchBar(
                        text: $searchText,
                        placeholder: "Search meals…",
                        isFocused: $searchFocused
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)

                    MealsContent(
                        searchText: searchText,
                        onLog: { showingLogMeal = $0 },
                        onFavorite: toggleFavorite(_:),
                        onDelete: deleteMeal(_:),
                        onEdit: { showingEditMeal = $0 },
                        onCreateFirst: { showingCreateMeal = true }
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)

                    Spacer(minLength: 60)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            // Show the unified clear accessory with Done for the search field
            .keyboardAccessory(
                focusedField: binding($searchFocused),
                equals: true,
                config: .done { searchFocused = nil }
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Meals")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateMeal = true } label: {
                        Image(systemName: AppTheme.Icons.add)
                            .font(.system(size: 17, weight: .semibold))
                            .imageScale(.medium)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Create meal")
                }
            }
            .sheet(isPresented: $showingCreateMeal) {
                CreateMealView()
            }
            .sheet(item: $showingLogMeal) { meal in
                LogMealView(meal: meal)
            }
            .sheet(item: $showingEditMeal) { meal in
                EditMealView(meal: meal)
            }
        }
    }

    // MARK: - Mutations
    private func toggleFavorite(_ meal: Meal) {
        meal.isFavorite.toggle()
        try? modelContext.save()
    }

    private func deleteMeal(_ meal: Meal) {
        modelContext.delete(meal)
        try? modelContext.save()
    }
}

// MARK: - Query-driven content

private struct MealsContent: View {
    let searchText: String
    let onLog: (Meal) -> Void
    let onFavorite: (Meal) -> Void
    let onDelete: (Meal) -> Void
    let onEdit: (Meal) -> Void
    let onCreateFirst: () -> Void

    // Minimal query (filter only). Manual sort keeps SwiftData happy across models.
    @Query private var baseMeals: [Meal]

    init(
        searchText: String,
        onLog: @escaping (Meal) -> Void,
        onFavorite: @escaping (Meal) -> Void,
        onDelete: @escaping (Meal) -> Void,
        onEdit: @escaping (Meal) -> Void,
        onCreateFirst: @escaping () -> Void
    ) {
        self.searchText = searchText
        self.onLog = onLog
        self.onFavorite = onFavorite
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onCreateFirst = onCreateFirst

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _baseMeals = Query(filter: #Predicate<Meal> { _ in true })
        } else {
            let q = searchText.lowercased()
            _baseMeals = Query(filter: #Predicate<Meal> { $0.name.localizedStandardContains(q) })
        }
    }

    // Manual ordering: favorites first, then lastUsedAt desc, then createdAt desc
    private var meals: [Meal] {
        baseMeals.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
            let l0 = $0.lastUsedAt ?? .distantPast
            let l1 = $1.lastUsedAt ?? .distantPast
            if l0 != l1 { return l0 > l1 }
            return $0.createdAt > $1.createdAt
        }
    }

    private var favoriteMeals: [Meal] { meals.filter { $0.isFavorite } }
    private var recentMeals: [Meal] { meals.filter { !$0.isFavorite && $0.lastUsedAt != nil } }
    private var otherMeals: [Meal] { meals.filter { !$0.isFavorite && $0.lastUsedAt == nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sectionSpacing) {
            if meals.isEmpty {
                EmptyMealsCard(onCreateFirst: onCreateFirst)
            } else {
                if !favoriteMeals.isEmpty {
                    SectionHeader("Favorites")
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(favoriteMeals) { meal in
                            MealRowCard(
                                meal: meal,
                                onTap: { onLog(meal) },
                                onFavorite: { onFavorite(meal) },
                                onDelete: { onDelete(meal) },
                                onEdit: { onEdit(meal) },
                                isFavorite: true
                            )
                        }
                    }
                }

                if !recentMeals.isEmpty {
                    SectionHeader("Recently Used")
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(recentMeals) { meal in
                            MealRowCard(
                                meal: meal,
                                onTap: { onLog(meal) },
                                onFavorite: { onFavorite(meal) },
                                onDelete: { onDelete(meal) },
                                onEdit: { onEdit(meal) },
                                isFavorite: false
                            )
                        }
                    }
                }

                if !otherMeals.isEmpty {
                    SectionHeader(searchText.isEmpty ? "All Meals" : "Other Meals")
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(otherMeals) { meal in
                            MealRowCard(
                                meal: meal,
                                onTap: { onLog(meal) },
                                onFavorite: { onFavorite(meal) },
                                onDelete: { onDelete(meal) },
                                onEdit: { onEdit(meal) },
                                isFavorite: false
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UI Pieces

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(AppTheme.Typography.title2)
            .foregroundStyle(AppTheme.Colors.labelPrimary)
            .padding(.top, AppTheme.Spacing.md)
    }
}

private struct EmptyMealsCard: View {
    let onCreateFirst: () -> Void
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.labelSecondary)

            Text("No meals yet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            Text("Create a meal to save ingredients and log portions faster.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.labelTertiary)
                .multilineTextAlignment(.center)

            Button(action: onCreateFirst) {
                HStack(spacing: 10) {
                    Image(systemName: AppTheme.Icons.add).imageScale(.medium)
                    Text("Create meal").font(AppTheme.Typography.bodyEmphasized)
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.vertical, AppTheme.Spacing.md)
                .foregroundStyle(.white)
                .background(AppTheme.Colors.accentGradient)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.cardPadding)
        .modernCard()
    }
}

private struct MealRowCard: View {
    let meal: Meal
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let isFavorite: Bool

    private var nutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) { meal.nutritionPer100g }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
                .modernCard()
                .contextMenu {
                    Button("Edit", action: onEdit)
                    Button(isFavorite ? "Remove Favorite" : "Favorite", action: onFavorite)
                    Button("Delete", role: .destructive, action: onDelete)
                }
        }
        .swipeActions(edge: .trailing) {
            Button("Edit", action: onEdit).tint(.blue)
            Button(isFavorite ? "Unfavorite" : "Favorite", action: onFavorite).tint(.yellow)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var content: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(meal.name)
                            .font(AppTheme.Typography.body).fontWeight(.medium)
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                            .lineLimit(2).multilineTextAlignment(.leading)
                        if meal.isFavorite {
                            Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass").font(.caption).foregroundStyle(AppTheme.Colors.labelSecondary)
                        Text("Yield: \(Int(meal.totalYieldGrams))g")
                            .font(AppTheme.Typography.caption).foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: AppTheme.Icons.calories).font(.caption).foregroundStyle(AppTheme.Colors.calories)
                        Text("\(Int(nutrition.calories)) kcal")
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                            .font(AppTheme.Typography.subheadline).fontWeight(.semibold)
                    }
                    Text("per 100g").font(AppTheme.Typography.caption).foregroundStyle(AppTheme.Colors.labelTertiary)
                }
            }
            HStack(spacing: 10) {
                Text("P \(String(format: "%.1f", nutrition.protein))g").foregroundStyle(AppTheme.Colors.protein)
                Text("•").foregroundStyle(AppTheme.Colors.labelSecondary)
                Text("C \(String(format: "%.1f", nutrition.carbs))g").foregroundStyle(AppTheme.Colors.carbs)
                Text("•").foregroundStyle(AppTheme.Colors.labelSecondary)
                Text("F \(String(format: "%.1f", nutrition.fat))g").foregroundStyle(AppTheme.Colors.fat)
                Spacer()
            }
            .font(AppTheme.Typography.caption)
        }
    }
}

// MARK: - Search UI

private struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool?>.Binding

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: AppTheme.Icons.search)
                .foregroundStyle(AppTheme.Colors.labelTertiary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .focused(isFocused, equals: true)
        }
        .modernField()
    }
}
