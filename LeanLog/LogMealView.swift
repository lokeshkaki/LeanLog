//
//  LogMealView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//

import SwiftUI
import SwiftData

struct LogMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let meal: Meal
    
    @State private var portionGrams: Double = 100
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var logAsIndividualIngredients = false
    @State private var showIngredients = false // Collapsed by default
    
    private var portionNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let nutrition = meal.nutritionPer100g
        let factor = portionGrams / 100.0
        
        return (
            calories: nutrition.calories * factor,
            protein: nutrition.protein * factor,
            carbs: nutrition.carbs * factor,
            fat: nutrition.fat * factor
        )
    }
    
    private var portionPercentage: Double {
        (portionGrams / meal.totalYieldGrams) * 100
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Meal Information Section
                mealInfoSection
                
                // Clean divider
                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(height: 1)
                
                // Logging Section
                ScrollView {
                    LazyVStack(spacing: 16) {
                        portionCard
                        nutritionCard
                        logSettingsCard
                        logButton
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Meal Information Section
    private var mealInfoSection: some View {
        VStack(spacing: 0) {
            // Header - consistent padding with cards below
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(meal.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if meal.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "scalemass")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Yield: \(Int(meal.totalYieldGrams))g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Created \(meal.createdDateString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Collapsible Ingredients - more apparent button
                if !meal.ingredients.isEmpty {
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showIngredients.toggle()
                            }
                        }) {
                            HStack {
                                Text("Ingredients")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("(\(meal.ingredients.count))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Text(showIngredients ? "Hide" : "Show")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                        .rotationEffect(.degrees(showIngredients ? 180 : 0))
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color.clear)
                        }
                        .buttonStyle(.plain)
                        
                        if showIngredients {
                            VStack(spacing: 0) {
                                ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(ingredient.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
                                            // Macros for each ingredient
                                            HStack(spacing: 8) {
                                                if let protein = ingredient.protein, protein > 0 {
                                                    Text("P \(String(format: "%.1f", protein * ingredient.quantity))g")
                                                        .font(.caption2)
                                                        .foregroundStyle(AppTheme.protein)
                                                }
                                                
                                                if let carbs = ingredient.carbs, carbs > 0 {
                                                    Text("C \(String(format: "%.1f", carbs * ingredient.quantity))g")
                                                        .font(.caption2)
                                                        .foregroundStyle(AppTheme.carbs)
                                                }
                                                
                                                if let fat = ingredient.fat, fat > 0 {
                                                    Text("F \(String(format: "%.1f", fat * ingredient.quantity))g")
                                                        .font(.caption2)
                                                        .foregroundStyle(AppTheme.fat)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "flame.fill")
                                                    .font(.caption2)
                                                    .foregroundStyle(AppTheme.calories)
                                                Text("\(Int(Double(ingredient.calories) * ingredient.quantity))")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text("kcal")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            // Moved servings underneath calories
                                            Text("\(String(format: "%.2g", ingredient.quantity))× serving")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    
                                    if index < meal.ingredients.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .padding(20) // Same padding as cards below
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    // MARK: - Logging Section Cards
    private var portionCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Select Portion")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Weight display
                HStack {
                    Text("Weight")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(portionGrams))g")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 12) {
                    Text("That's \(String(format: "%.1f", portionPercentage))% of the total meal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Clean slider
                    VStack(spacing: 8) {
                        Slider(value: $portionGrams, in: 10...meal.totalYieldGrams, step: 5)
                        
                        HStack {
                            Text("10g")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("\(Int(meal.totalYieldGrams))g")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
    
    private var nutritionCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Nutrition Preview")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("For \(Int(portionGrams))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .systemFill))
                    )
            }
            
            // Modern nutrition grid with icons at bottom
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    NutritionMiniCard(
                        icon: "flame.fill",
                        color: AppTheme.calories,
                        value: "\(Int(round(portionNutrition.calories)))",
                        unit: "kcal",
                        label: "Calories"
                    )
                    
                    NutritionMiniCard(
                        icon: "leaf.fill",
                        color: AppTheme.protein,
                        value: String(format: "%.1f", portionNutrition.protein),
                        unit: "g",
                        label: "Protein"
                    )
                }
                
                HStack(spacing: 16) {
                    NutritionMiniCard(
                        icon: "square.stack.3d.up.fill",
                        color: AppTheme.carbs,
                        value: String(format: "%.1f", portionNutrition.carbs),
                        unit: "g",
                        label: "Carbs"
                    )
                    
                    NutritionMiniCard(
                        icon: "drop.fill",
                        color: AppTheme.fat,
                        value: String(format: "%.1f", portionNutrition.fat),
                        unit: "g",
                        label: "Fat"
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
    
    private var logSettingsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Log Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 20) {
                HStack {
                    Text("Date")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                // Redesigned log type - stack vertically for long names
                VStack(spacing: 12) {
                    HStack {
                        Text("Log as")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        // Single meal entry - full width horizontal card
                        Button(action: { logAsIndividualIngredients = false }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.stack")
                                    .font(.title3)
                                    .foregroundStyle(logAsIndividualIngredients ? Color.secondary : Color.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Meal")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(logAsIndividualIngredients ? Color.secondary : Color.blue)
                                    
                                    Text("1 food entry")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if !logAsIndividualIngredients {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(logAsIndividualIngredients ? Color.clear : Color.blue.opacity(0.1))
                                    .stroke(logAsIndividualIngredients ? Color(uiColor: .separator) : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Individual ingredients - full width horizontal card
                        Button(action: { logAsIndividualIngredients = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "list.bullet")
                                    .font(.title3)
                                    .foregroundStyle(logAsIndividualIngredients ? Color.blue : Color.secondary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ingredients")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(logAsIndividualIngredients ? Color.blue : Color.secondary)
                                    
                                    Text("\(meal.ingredients.count) separate food entries")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Spacer()
                                
                                if logAsIndividualIngredients {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(logAsIndividualIngredients ? Color.blue.opacity(0.1) : Color.clear)
                                    .stroke(logAsIndividualIngredients ? Color.blue.opacity(0.3) : Color(uiColor: .separator), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
    
    private var logButton: some View {
        Button(action: logMealPortion) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Log to Food Diary")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue)
            )
        }
        .padding(.bottom, 20)
    }
    
    private func logMealPortion() {
        let portionFactor = portionGrams / meal.totalYieldGrams
        let timestamp = Date()
        
        if logAsIndividualIngredients {
            // Log each ingredient separately, scaled by portion
            for ingredient in meal.ingredients {
                let scaledCalories = Int(round(Double(ingredient.calories) * ingredient.quantity * portionFactor))
                let scaledProtein = (ingredient.protein ?? 0) * ingredient.quantity * portionFactor
                let scaledCarbs = (ingredient.carbs ?? 0) * ingredient.quantity * portionFactor
                let scaledFat = (ingredient.fat ?? 0) * ingredient.quantity * portionFactor
                
                let entry = FoodEntry(
                    name: ingredient.name,
                    calories: scaledCalories,
                    protein: scaledProtein > 0 ? scaledProtein : nil,
                    carbs: scaledCarbs > 0 ? scaledCarbs : nil,
                    fat: scaledFat > 0 ? scaledFat : nil,
                    servingSize: ingredient.servingSize,
                    servingUnit: ingredient.servingUnit,
                    date: selectedDate,
                    timestamp: timestamp,
                    source: "Meal: \(meal.name)",
                    externalId: nil
                )
                
                modelContext.insert(entry)
            }
        } else {
            // Log as single combined meal entry
            let nutrition = portionNutrition
            
            let entry = FoodEntry(
                name: meal.name,
                calories: Int(round(nutrition.calories)),
                protein: nutrition.protein,
                carbs: nutrition.carbs,
                fat: nutrition.fat,
                servingSize: portionGrams,
                servingUnit: "g",
                date: selectedDate,
                timestamp: timestamp,
                source: "Meal",
                externalId: nil
            )
            
            modelContext.insert(entry)
        }
        
        // Update meal's last used date
        meal.lastUsedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error logging meal portion: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct NutritionMiniCard: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Value at top, centered
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Icon and label at bottom
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
        )
    }
}
