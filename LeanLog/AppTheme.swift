//
//  AppTheme.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct AppTheme {
    // MARK: - Macro Colors
    static let calories = Color(red: 1.0, green: 0.65, blue: 0.2)    // Warm amber
    static let protein = Color(red: 0.4, green: 0.7, blue: 0.3)     // Forest green
    static let carbs = Color(red: 0.8, green: 0.5, blue: 0.9)       // Soft purple
    static let fat = Color(red: 1.0, green: 0.8, blue: 0.3)         // Golden yellow
    
    // MARK: - Progress Colors
    static let progressNormal = Color.primary
    static let progressWarning = Color.yellow
    static let progressOver = Color.red
    
    // MARK: - UI Colors
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let systemBackground = Color(uiColor: .systemBackground)
    static let secondary = Color.secondary
    static let tertiary = Color(uiColor: .tertiaryLabel)
    
    // MARK: - Progress Color Logic (Updated - No yellow warning, only red when over)
    static func macroProgressColor(for value: Double, goal: Double, baseColor: Color) -> Color {
        if value > goal {
            return progressOver
        } else {
            return baseColor
        }
    }
    
    static func caloriesProgressColor(for calories: Int, goal: Int) -> Color {
        if calories > goal {
            return progressOver
        } else {
            return AppTheme.calories  // Fixed: return the Color, not the Int parameter
        }
    }
}

// MARK: - Macro Extensions
extension AppTheme {
    static func macroIcon(for macro: MacroType) -> String {
        switch macro {
        case .calories: return "flame.fill"
        case .protein: return "leaf.fill"
        case .carbs: return "square.stack.3d.up.fill"
        case .fat: return "drop.fill"
        }
    }
    
    static func macroColor(for macro: MacroType) -> Color {
        switch macro {
        case .calories: return calories
        case .protein: return protein
        case .carbs: return carbs
        case .fat: return fat
        }
    }
}

enum MacroType {
    case calories, protein, carbs, fat
}
