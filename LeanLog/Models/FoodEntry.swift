//
//  FoodEntry.swift
//  LeanLog
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    // Identity
    @Attribute(.unique) var id: UUID

    // Core info
    var name: String
    var calories: Int

    // Serving
    var servingSize: Double?
    var servingUnit: String?

    // Timestamps
    // date: normalized to startOfDay for fast day-range filtering
    // timestamp: exact time for ordering and time gap UI
    var date: Date
    var timestamp: Date

    // Provenance
    var source: String?
    var externalId: String? // e.g., barcode

    // MARK: - Macronutrients (per serving, in grams)
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    
    // MARK: - Carbohydrate Details (grams)
    var sugars: Double?
    var fiber: Double?
    
    // MARK: - Fat Details (grams)
    var saturatedFat: Double?
    var transFat: Double?
    var monounsaturatedFat: Double?
    var polyunsaturatedFat: Double?
    
    // MARK: - Cholesterol & Sodium (grams)
    var cholesterol: Double?
    var sodium: Double?
    var salt: Double?
    
    // MARK: - Major Minerals (grams)
    var potassium: Double?
    var calcium: Double?
    var iron: Double?
    var magnesium: Double?
    var phosphorus: Double?
    var zinc: Double?
    
    // MARK: - Trace Minerals (grams)
    var selenium: Double?
    var copper: Double?
    var manganese: Double?
    var chromium: Double?
    var molybdenum: Double?
    var iodine: Double?
    var chloride: Double?
    
    // MARK: - Vitamins (grams)
    var vitaminA: Double?
    var vitaminC: Double?
    var vitaminD: Double?
    var vitaminE: Double?
    var vitaminK: Double?
    
    // MARK: - B Vitamins (grams)
    var thiamin: Double?        // B1
    var riboflavin: Double?     // B2
    var niacin: Double?         // B3
    var pantothenicAcid: Double? // B5
    var vitaminB6: Double?
    var biotin: Double?         // B7
    var folate: Double?         // B9
    var vitaminB12: Double?
    
    // MARK: - Other Nutrients (grams)
    var choline: Double?

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        servingSize: Double? = nil,
        servingUnit: String? = nil,
        date: Date,
        timestamp: Date,
        source: String? = nil,
        externalId: String? = nil,
        // Macros
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        // Carb details
        sugars: Double? = nil,
        fiber: Double? = nil,
        // Fat details
        saturatedFat: Double? = nil,
        transFat: Double? = nil,
        monounsaturatedFat: Double? = nil,
        polyunsaturatedFat: Double? = nil,
        // Cholesterol & sodium
        cholesterol: Double? = nil,
        sodium: Double? = nil,
        salt: Double? = nil,
        // Major minerals
        potassium: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        magnesium: Double? = nil,
        phosphorus: Double? = nil,
        zinc: Double? = nil,
        // Trace minerals
        selenium: Double? = nil,
        copper: Double? = nil,
        manganese: Double? = nil,
        chromium: Double? = nil,
        molybdenum: Double? = nil,
        iodine: Double? = nil,
        chloride: Double? = nil,
        // Vitamins
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        // B Vitamins
        thiamin: Double? = nil,
        riboflavin: Double? = nil,
        niacin: Double? = nil,
        pantothenicAcid: Double? = nil,
        vitaminB6: Double? = nil,
        biotin: Double? = nil,
        folate: Double? = nil,
        vitaminB12: Double? = nil,
        // Other
        choline: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.date = Calendar.current.startOfDay(for: date)
        self.timestamp = timestamp
        self.source = source
        self.externalId = externalId
        
        // Macros
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        
        // Carb details
        self.sugars = sugars
        self.fiber = fiber
        
        // Fat details
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.monounsaturatedFat = monounsaturatedFat
        self.polyunsaturatedFat = polyunsaturatedFat
        
        // Cholesterol & sodium
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.salt = salt
        
        // Major minerals
        self.potassium = potassium
        self.calcium = calcium
        self.iron = iron
        self.magnesium = magnesium
        self.phosphorus = phosphorus
        self.zinc = zinc
        
        // Trace minerals
        self.selenium = selenium
        self.copper = copper
        self.manganese = manganese
        self.chromium = chromium
        self.molybdenum = molybdenum
        self.iodine = iodine
        self.chloride = chloride
        
        // Vitamins
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        
        // B Vitamins
        self.thiamin = thiamin
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.pantothenicAcid = pantothenicAcid
        self.vitaminB6 = vitaminB6
        self.biotin = biotin
        self.folate = folate
        self.vitaminB12 = vitaminB12
        
        // Other
        self.choline = choline
    }
}
