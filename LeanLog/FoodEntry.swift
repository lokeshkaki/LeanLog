//
//  FoodEntry.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/20/25.
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    var name: String
    var calories: Int
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var servingSize: Double?
    var servingUnit: String?
    var date: Date
    var timestamp: Date  // New field for exact log time
    var source: String?
    var externalId: String?
    
    init(name: String, calories: Int, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil, servingSize: Double? = nil, servingUnit: String? = nil, date: Date, timestamp: Date? = nil, source: String? = nil, externalId: String? = nil) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.date = date
        self.timestamp = timestamp ?? Date()  // Default to current time
        self.source = source
        self.externalId = externalId
    }
}
