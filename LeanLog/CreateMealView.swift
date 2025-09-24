//
//  CreateMealView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//

import SwiftUI
import SwiftData

struct CreateMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var mealName = ""
    @State private var totalYieldGrams = ""
    @State private var ingredients: [MealIngredient] = []
    @State private var showingAddIngredient = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case mealName, totalYield
    }
    
    private var isValidMeal: Bool {
        !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !totalYieldGrams.isEmpty &&
        Double(totalYieldGrams) ?? 0 > 0 &&
        !ingredients.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    TextField("Meal name (e.g., Chicken Rice Bowl)", text: $mealName)
                        .focused($focusedField, equals: .mealName)
                    
                    HStack {
                        TextField("Total yield", text: $totalYieldGrams)
                            .focused($focusedField, equals: .totalYield)
                            .keyboardType(.numberPad)
                        Text("grams")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Enter the total weight after cooking/preparation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        IngredientRow(ingredient: ingredient) {
                            ingredients.remove(at: index)
                        }
                    }
                    .onDelete(perform: deleteIngredient)
                    
                    Button(action: { showingAddIngredient = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Ingredient")
                            Spacer()
                        }
                    }
                } header: {
                    HStack {
                        Text("Ingredients")
                        Spacer()
                        if !ingredients.isEmpty {
                            Text("\(ingredients.count) item\(ingredients.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    if ingredients.isEmpty {
                        Text("Add the ingredients that go into this meal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !ingredients.isEmpty && !totalYieldGrams.isEmpty,
                   let yieldGrams = Double(totalYieldGrams), yieldGrams > 0 {
                    nutritionPreviewSection(yieldGrams: yieldGrams)
                }
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMeal() }
                        .disabled(!isValidMeal)
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView { ingredient in
                    ingredients.append(ingredient)
                }
            }
        }
    }
    
    private func nutritionPreviewSection(yieldGrams: Double) -> some View {
        Section("Nutrition Preview (per 100g)") {
            let totalCalories = ingredients.reduce(0.0) { sum, ingredient in
                sum + Double(ingredient.calories) * ingredient.quantity
            }
            let totalProtein = ingredients.reduce(0.0) { sum, ingredient in
                sum + (ingredient.protein ?? 0) * ingredient.quantity
            }
            let totalCarbs = ingredients.reduce(0.0) { sum, ingredient in
                sum + (ingredient.carbs ?? 0) * ingredient.quantity
            }
            let totalFat = ingredients.reduce(0.0) { sum, ingredient in
                sum + (ingredient.fat ?? 0) * ingredient.quantity
            }
            
            let factor = 100.0 / yieldGrams
            
            NutritionPreviewRow(
                icon: "flame.fill",
                color: AppTheme.calories,
                label: "Calories",
                value: Int(totalCalories * factor),
                unit: "kcal"
            )
            
            NutritionPreviewRow(
                icon: "leaf.fill",
                color: AppTheme.protein,
                label: "Protein",
                value: totalProtein * factor,
                unit: "g"
            )
            
            NutritionPreviewRow(
                icon: "square.stack.3d.up.fill",
                color: AppTheme.carbs,
                label: "Carbs",
                value: totalCarbs * factor,
                unit: "g"
            )
            
            NutritionPreviewRow(
                icon: "drop.fill",
                color: AppTheme.fat,
                label: "Fat",
                value: totalFat * factor,
                unit: "g"
            )
        }
    }
    
    private func deleteIngredient(offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func saveMeal() {
        guard let yieldGrams = Double(totalYieldGrams) else { return }
        
        let meal = Meal(
            name: mealName.trimmingCharacters(in: .whitespacesAndNewlines),
            totalYieldGrams: yieldGrams
        )
        
        // Add ingredients to meal
        for ingredient in ingredients {
            ingredient.meal = meal
            meal.ingredients.append(ingredient)
        }
        
        modelContext.insert(meal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving meal: \(error)")
        }
    }
}

struct IngredientRow: View {
    let ingredient: MealIngredient
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack {
                    Text("\(String(format: "%.2g", ingredient.quantity))×")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let servingSize = ingredient.servingSize,
                       let servingUnit = ingredient.servingUnit {
                        Text("(\(String(format: "%.1f", servingSize)) \(servingUnit))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let source = ingredient.source {
                        Text("• \(source)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(Double(ingredient.calories) * ingredient.quantity)) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.calories)
                
                if let protein = ingredient.protein {
                    Text("P: \(String(format: "%.1f", protein * ingredient.quantity))g")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct NutritionPreviewRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: Any
    let unit: String
    
    var body: some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            Spacer()
            
            if let intValue = value as? Int {
                Text("\(intValue) \(unit)")
                    .fontWeight(.medium)
            } else if let doubleValue = value as? Double {
                Text("\(String(format: "%.1f", doubleValue)) \(unit)")
                    .fontWeight(.medium)
            }
        }
    }
}
