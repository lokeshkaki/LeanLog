//
//  AppTheme.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Modern palette + components + legacy aliases for backward compatibility
//

import SwiftUI
import UIKit

struct AppTheme {
    // MARK: - Dynamic Colors (Light/Dark aware)
    struct Colors {
        private static func dynamic(light: UIColor, dark: UIColor) -> Color {
            Color(UIColor { tc in
                tc.userInterfaceStyle == .dark ? dark : light
            })
        }

        // Backgrounds
        static let background = dynamic(
            light: .systemGroupedBackground,
            dark: .black
        )

        static let surface = dynamic(
            light: .secondarySystemGroupedBackground,
            dark: UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        )

        static let surfaceElevated = dynamic(
            light: .tertiarySystemGroupedBackground,
            dark: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        )

        static let input = dynamic(
            light: UIColor { _ in
                UIColor.secondarySystemBackground.withAlphaComponent(0.9)
            },
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1.0)
        )

        static let stroke = dynamic(
            light: UIColor.separator.withAlphaComponent(0.25),
            dark: UIColor.white.withAlphaComponent(0.06)
        )

        static let subtleStroke = dynamic(
            light: UIColor.label.withAlphaComponent(0.06),
            dark: UIColor.white.withAlphaComponent(0.03)
        )

        // Labels
        static let labelPrimary = Color.primary
        static let labelSecondary = Color.secondary
        static let labelTertiary = Color.secondary.opacity(0.6)
        static let placeholder = Color.secondary.opacity(0.4)

        // Accents
        static let accent = dynamic(
            light: UIColor.systemBlue,
            dark: UIColor(red: 0.10, green: 0.57, blue: 1.0, alpha: 1.0)
        )

        static let accentPressed = dynamic(
            light: UIColor.systemBlue.withAlphaComponent(0.9),
            dark: UIColor(red: 0.08, green: 0.46, blue: 0.88, alpha: 1.0)
        )

        static let success = dynamic(
            light: UIColor.systemGreen,
            dark: UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
        )

        static let warning = dynamic(
            light: UIColor.systemOrange,
            dark: UIColor(red: 1.0, green: 0.65, blue: 0.10, alpha: 1.0)
        )

        static let destructive = dynamic(
            light: UIColor.systemRed,
            dark: UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        )

        // Macros (vibrant, system-aligned)
        static let calories = Color.orange
        static let protein = Color.green
        static let carbs = Color.purple
        static let fat = Color.yellow

        // Accents as gradients
        static let accentGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardStrokeGradient = LinearGradient(
            colors: [Colors.subtleStroke.opacity(0.8), Colors.subtleStroke.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Legacy Compatibility (aliases for older references)
    // Backgrounds
    static let primaryBackground = Colors.background
    static let secondaryBackground = Colors.surface
    static let tertiaryBackground = Colors.surfaceElevated

    // Surfaces
    static let cardBackground = Colors.surface
    static let cardBackgroundElevated = Colors.surfaceElevated
    static let inputBackground = Colors.input
    static let separatorColor = Colors.stroke

    // Text
    static let primaryText = Colors.labelPrimary
    static let secondaryText = Colors.labelSecondary
    static let tertiaryText = Colors.labelTertiary
    static let placeholderText = Colors.placeholder

    // Macro & status colors
    static let calories = Colors.calories
    static let protein = Colors.protein
    static let carbs = Colors.carbs
    static let fat = Colors.fat

    static let accentBlue = Colors.accent
    static let accentBlueTapped = Colors.accentPressed
    static let destructiveRed = Colors.destructive
    static let warningOrange = Colors.warning
    static let successGreen = Colors.success

    // Progress
    static let progressNormal = Colors.labelSecondary
    static let progressOver = Colors.destructive
    static let progressComplete = Colors.success

    // MARK: - Typography
    enum Typography {
        static let largeTitle: Font = .largeTitle.weight(.bold)
        static let title: Font = .title.weight(.bold)
        static let title2: Font = .title2.weight(.bold)
        static let title3: Font = .title3.weight(.semibold)
        static let headline: Font = .headline.weight(.semibold)
        static let body: Font = .body
        static let bodyEmphasized: Font = .body.weight(.semibold)
        static let callout: Font = .callout
        static let subheadline: Font = .subheadline
        static let footnote: Font = .footnote
        static let caption: Font = .caption
        static let caption2: Font = .caption2
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let xxxxL: CGFloat = 40
        static let xxxxxL: CGFloat = 48
        static let huge: CGFloat = 64

        static let cardPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let screenPadding: CGFloat = 20
        static let inputPadding: CGFloat = 14
        static let rowSpacing: CGFloat = 16
    }

    // MARK: - Corners
    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Icons (SF Symbols)
    enum Icons {
        static let calories = "flame.fill"
        static let protein = "bolt.heart.fill"
        static let carbs = "square.stack.3d.up.fill"
        static let fat = "drop.fill"

        static let add = "plus"
        static let search = "magnifyingglass"
        static let share = "square.and.arrow.up"
        static let edit = "pencil"
        static let delete = "trash"
        static let back = "chevron.left"
        static let close = "xmark"
        static let save = "checkmark.circle.fill"
        static let calendar = "calendar"
        static let clock = "clock"
        static let warning = "exclamationmark.triangle.fill"
        static let function = "function"
    }

    // MARK: - Logic Helpers
    static func macroProgressColor(for value: Double, goal: Double, baseColor: Color) -> Color {
        value > goal ? Colors.destructive : baseColor
    }

    static func caloriesProgressColor(for calories: Int, goal: Int) -> Color {
        calories > goal ? Colors.destructive : Colors.calories
    }

    static func macroColor(for macro: MacroType) -> Color {
        switch macro {
        case .calories: return Colors.calories
        case .protein:  return Colors.protein
        case .carbs:    return Colors.carbs
        case .fat:      return Colors.fat
        }
    }

    static func macroIcon(for macro: MacroType) -> String {
        switch macro {
        case .calories: return Icons.calories
        case .protein:  return Icons.protein
        case .carbs:    return Icons.carbs
        case .fat:      return Icons.fat
        }
    }
}

// MARK: - View Modifiers
extension View {
    // Screen background
    func screenBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppTheme.Colors.background)
    }

    // Navigation styling
    func modernNavigation() -> some View {
        self
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // Modern glass card
    func modernCard(elevated: Bool = false) -> some View {
        self
            .padding(AppTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(elevated ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .strokeBorder(AppTheme.Colors.cardStrokeGradient, lineWidth: 1)
                    }
            )
            .shadow(color: Color.black.opacity(elevated ? 0.35 : 0.25), radius: elevated ? 18 : 12, x: 0, y: elevated ? 10 : 6)
    }

    // Input styling
    func modernField(focused: Bool = false) -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.Colors.input)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .strokeBorder(focused ? AppTheme.Colors.accent : AppTheme.Colors.subtleStroke, lineWidth: focused ? 2 : 1)
                    }
            )
            .shadow(color: Color.black.opacity(focused ? 0.35 : 0.18), radius: focused ? 10 : 6, x: 0, y: focused ? 6 : 3)
    }

    // Legacy wrappers for compatibility with existing views
    func primaryCard() -> some View {
        self.modernCard(elevated: false)
    }

    func elevatedCard() -> some View {
        self.modernCard(elevated: true)
    }

    func modernInput(focused: Bool = false) -> some View {
        self.modernField(focused: focused)
    }
}

// MARK: - Buttons
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.bodyEmphasized)
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                Capsule(style: .circular)
                    .fill(AppTheme.Colors.accentGradient)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Enum
enum MacroType: CaseIterable {
    case calories, protein, carbs, fat
}
