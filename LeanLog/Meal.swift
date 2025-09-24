//
//  Meal.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//

import Foundation
import SwiftData

@Model
final class Meal {
    var name: String
    var totalYieldGrams: Double
    var createdAt: Date
    var lastUsedAt: Date?
    var isFavorite: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \MealIngredient.meal)
    var ingredients: [MealIngredient] = []
    
    init(name: String, totalYieldGrams: Double) {
        self.name = name
        self.totalYieldGrams = totalYieldGrams
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.isFavorite = false
    }
    
    // Formatted creation date
    var createdDateString: String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    // Computed nutrition per 100g
    var nutritionPer100g: (calories: Double, protein: Double, carbs: Double, fat: Double) {
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
        
        let factor = 100.0 / totalYieldGrams
        return (
            calories: totalCalories * factor,
            protein: totalProtein * factor,
            carbs: totalCarbs * factor,
            fat: totalFat * factor
        )
    }
}

@Model
final class MealIngredient {
    var name: String
    var quantity: Double  // multiplier (e.g., 1.5 servings)
    var calories: Int     // per single serving
    var protein: Double?  // per single serving
    var carbs: Double?    // per single serving
    var fat: Double?      // per single serving
    var servingSize: Double?
    var servingUnit: String?
    var source: String?
    
    var meal: Meal?
    
    init(name: String, quantity: Double, calories: Int, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil, servingSize: Double? = nil, servingUnit: String? = nil, source: String? = nil) {
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.source = source
    }
}
