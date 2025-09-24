//
//  MealsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//

import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Meal.lastUsedAt, order: .reverse),
                  SortDescriptor(\Meal.createdAt, order: .reverse)])
    private var meals: [Meal]
    
    @State private var showingCreateMeal = false
    @State private var showingLogMeal: Meal? = nil
    @State private var searchText = ""
    
    private var filteredMeals: [Meal] {
        if searchText.isEmpty {
            return meals
        } else {
            return meals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var favoriteMeals: [Meal] {
        filteredMeals.filter { $0.isFavorite }
    }
    
    private var recentMeals: [Meal] {
        filteredMeals.filter { !$0.isFavorite && $0.lastUsedAt != nil }
    }
    
    private var otherMeals: [Meal] {
        filteredMeals.filter { !$0.isFavorite && $0.lastUsedAt == nil }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if meals.isEmpty {
                    emptyState
                } else {
                    mealsList
                }
            }
            .navigationTitle("Meals")
            .searchable(text: $searchText, prompt: "Search meals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateMeal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateMeal) {
                CreateMealView()
            }
            .sheet(item: $showingLogMeal) { meal in
                LogMealView(meal: meal)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Meals Created")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first meal to start meal prepping and logging portions")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: { showingCreateMeal = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Meal")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var mealsList: some View {
        List {
            if !favoriteMeals.isEmpty {
                Section("Favorites") {
                    ForEach(favoriteMeals) { meal in
                        MealRow(meal: meal) {
                            showingLogMeal = meal
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Remove Favorite") {
                                toggleFavorite(meal)
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            
            if !recentMeals.isEmpty {
                Section("Recently Used") {
                    ForEach(recentMeals) { meal in
                        MealRow(meal: meal) {
                            showingLogMeal = meal
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Favorite") {
                                toggleFavorite(meal)
                            }
                            .tint(.yellow)
                            
                            Button("Delete", role: .destructive) {
                                deleteMeal(meal)
                            }
                        }
                    }
                }
            }
            
            if !otherMeals.isEmpty {
                Section(searchText.isEmpty ? "All Meals" : "Other Meals") {
                    ForEach(otherMeals) { meal in
                        MealRow(meal: meal) {
                            showingLogMeal = meal
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Favorite") {
                                toggleFavorite(meal)
                            }
                            .tint(.yellow)
                            
                            Button("Delete", role: .destructive) {
                                deleteMeal(meal)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func toggleFavorite(_ meal: Meal) {
        meal.isFavorite.toggle()
        try? modelContext.save()
    }
    
    private func deleteMeal(_ meal: Meal) {
        modelContext.delete(meal)
        try? modelContext.save()
    }
}

struct MealRow: View {
    let meal: Meal
    let onTap: () -> Void
    
    private var nutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        meal.nutritionPer100g
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Top row - consistent with home view
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(meal.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                            
                            if meal.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "scalemass")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Yield: \(Int(meal.totalYieldGrams))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.calories)
                            Text("\(Int(nutrition.calories)) kcal")
                                .foregroundStyle(.primary)
                                .fontWeight(.semibold)
                                .font(.subheadline)
                        }
                        
                        Text("per 100g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                // Bottom row - macros like home view
                HStack(spacing: 8) {
                    Text("P \(String(format: "%.1f", nutrition.protein))g")
                        .foregroundStyle(AppTheme.protein)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("C \(String(format: "%.1f", nutrition.carbs))g")
                        .foregroundStyle(AppTheme.carbs)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("F \(String(format: "%.1f", nutrition.fat))g")
                        .foregroundStyle(AppTheme.fat)
                    
                    Spacer()
                }
                .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
