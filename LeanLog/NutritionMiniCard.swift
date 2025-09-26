//
//  NutritionMiniCard.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/26/25.
//

import SwiftUI

public struct NutritionMiniCard: View {
    public let icon: String
    public let color: Color
    public let value: String
    public let unit: String
    public let label: String

    public init(icon: String, color: Color, value: String, unit: String, label: String) {
        self.icon = icon
        self.color = color
        self.value = value
        self.unit = unit
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(unit)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(AppTheme.Colors.input)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .stroke(AppTheme.Colors.subtleStroke, lineWidth: 1)
                }
        )
    }
}
