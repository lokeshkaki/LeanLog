//
//  SettingsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Consistent theming + checkmark toolbar + input sanitization + transparent accessory
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000
    @AppStorage("proteinGoal") private var proteinGoal = 100.0
    @AppStorage("carbGoal") private var carbGoal = 250.0
    @AppStorage("fatGoal") private var fatGoal = 70.0
    
    // Convert to strings for proper text field handling
    @State private var calorieGoalText = ""
    @State private var proteinGoalText = ""
    @State private var carbGoalText = ""
    @State private var fatGoalText = ""
    
    @FocusState private var focusedField: Field?
    enum Field: CaseIterable, Hashable {
        case calories, protein, carbs, fat
    }

    // Locale-aware number IO
    private let numberIO = LocalizedNumberIO(maxFractionDigits: 1)
    
    private var orderedFields: [Field] { [.calories, .protein, .carbs, .fat] }
    private var focusedIndex: Int? { focusedField.flatMap { orderedFields.firstIndex(of: $0) } }
    private var canGoPrev: Bool { (focusedIndex ?? 0) > 0 }
    private var canGoNext: Bool { (focusedIndex ?? (orderedFields.count - 1)) < orderedFields.count - 1 }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // MARK: Custom Header with App Title
                    HStack {
                        Text("Lean Log")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(AppTheme.Colors.background)
                    
                    Form {
                        Section {
                            goalRow(
                                label: "Calories",
                                icon: AppTheme.Icons.calories,
                                color: AppTheme.Colors.calories,
                                text: $calorieGoalText,
                                unit: "kcal",
                                field: .calories,
                                keyboard: .numberPad
                            )
                            .id(Field.calories)
                            
                            goalRow(
                                label: "Protein",
                                icon: AppTheme.Icons.protein,
                                color: AppTheme.Colors.protein,
                                text: $proteinGoalText,
                                unit: "g",
                                field: .protein,
                                keyboard: .decimalPad
                            )
                            .id(Field.protein)
                            
                            goalRow(
                                label: "Carbs",
                                icon: AppTheme.Icons.carbs,
                                color: AppTheme.Colors.carbs,
                                text: $carbGoalText,
                                unit: "g",
                                field: .carbs,
                                keyboard: .decimalPad
                            )
                            .id(Field.carbs)
                            
                            goalRow(
                                label: "Fat",
                                icon: AppTheme.Icons.fat,
                                color: AppTheme.Colors.fat,
                                text: $fatGoalText,
                                unit: "g",
                                field: .fat,
                                keyboard: .decimalPad
                            )
                            .id(Field.fat)
                        } header: {
                            Text("Daily Goals")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                        
                        Section {
                            HStack {
                                Text("Version")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                                Spacer()
                                Text("1.0.0")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                            }
                            
                            HStack {
                                Text("Developer")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                                Spacer()
                                Text("LeanLog Team")
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                            }
                        } header: {
                            Text("About")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                        
                        Section {
                            Button("Export All Data") {
                                // TODO: Implement export functionality
                            }
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.accent)
                            
                            Button("Clear All Data", role: .destructive) {
                                // TODO: Implement clear data functionality
                            }
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.destructive)
                        } header: {
                            Text("Data")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.Colors.background)
                    .onChange(of: focusedField) { _ in scrollFocusedIntoView(proxy) }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                        scrollFocusedIntoView(proxy)
                        KeyboardAccessoryStyler.shared.makeTransparent()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)) { _ in
                        KeyboardAccessoryStyler.shared.makeTransparent()
                    }
                }
                .screenBackground()
                .navigationBarHidden(true)
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    // Keyboard toolbar with proper field navigation + checkmark
                    ToolbarItemGroup(placement: .keyboard) {
                        if focusedField != nil {
                            Button(action: previousField) {
                                Image(systemName: "chevron.up").imageScale(.medium)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canGoPrev)
                            .accessibilityLabel("Previous field")

                            Button(action: nextField) {
                                Image(systemName: "chevron.down").imageScale(.medium)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canGoNext)
                            .accessibilityLabel("Next field")

                            Spacer()

                            Button(action: { focusedField = nil }) {
                                Image(systemName: "checkmark")
                                    .imageScale(.medium)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Done editing")
                        }
                    }
                }
            }
        }
        .onAppear {
            syncTextFields()
        }
        .onChange(of: calorieGoalText) { updateCalorieGoal() }
        .onChange(of: proteinGoalText) { updateProteinGoal() }
        .onChange(of: carbGoalText) { updateCarbGoal() }
        .onChange(of: fatGoalText) { updateFatGoal() }
    }

    // MARK: - Goal Row Component

    private func goalRow(
        label: String,
        icon: String,
        color: Color,
        text: Binding<String>,
        unit: String,
        field: Field,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(AppTheme.Typography.body)
                .foregroundStyle(color)
            
            Spacer()
            
            TextField(getPlaceholder(for: field), text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($focusedField, equals: field)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
                .submitLabel(field == .fat ? .done : .next)
                .onSubmit { field == .fat ? (focusedField = nil) : advanceFrom(field) }
                .onChange(of: text.wrappedValue) { newValue in
                    let sanitized = keyboard == .numberPad ?
                        numberIO.sanitizeInteger(newValue) :
                        numberIO.sanitizeDecimal(newValue)
                    if sanitized != newValue {
                        text.wrappedValue = sanitized
                    }
                }
            
            Text(unit)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
        }
    }

    // MARK: - Field Navigation

    private func advanceFrom(_ field: Field) {
        if let idx = orderedFields.firstIndex(of: field), idx < orderedFields.count - 1 {
            focusedField = orderedFields[idx + 1]
        } else {
            focusedField = nil
        }
    }

    private func nextField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        focusedField = orderedFields[min(idx + 1, orderedFields.count - 1)]
    }

    private func previousField() {
        guard let current = focusedField, let idx = orderedFields.firstIndex(of: current) else { return }
        focusedField = orderedFields[max(idx - 1, 0)]
    }

    private func scrollFocusedIntoView(_ proxy: ScrollViewProxy) {
        guard let field = focusedField else { return }
        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .center) }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(field, anchor: .center) }
        }
    }

    // MARK: - Data Sync

    private func getPlaceholder(for field: Field) -> String {
        switch field {
        case .calories: return "2000"
        case .protein: return "100"
        case .carbs: return "250"
        case .fat: return "70"
        }
    }

    private func syncTextFields() {
        calorieGoalText = String(dailyCalorieGoal)
        proteinGoalText = proteinGoal > 0 ? String(format: "%.1f", proteinGoal).replacingOccurrences(of: ".0", with: "") : ""
        carbGoalText = carbGoal > 0 ? String(format: "%.1f", carbGoal).replacingOccurrences(of: ".0", with: "") : ""
        fatGoalText = fatGoal > 0 ? String(format: "%.1f", fatGoal).replacingOccurrences(of: ".0", with: "") : ""
    }

    private func updateCalorieGoal() {
        if let value = Int(calorieGoalText), value > 0 {
            dailyCalorieGoal = value
        }
    }

    private func updateProteinGoal() {
        if let value = numberIO.parseDecimal(proteinGoalText), value > 0 {
            proteinGoal = value
        }
    }

    private func updateCarbGoal() {
        if let value = numberIO.parseDecimal(carbGoalText), value > 0 {
            carbGoal = value
        }
    }

    private func updateFatGoal() {
        if let value = numberIO.parseDecimal(fatGoalText), value > 0 {
            fatGoal = value
        }
    }
}

// MARK: - Locale-aware number IO helper

private struct LocalizedNumberIO {
    private let formatter: NumberFormatter

    init(maxFractionDigits: Int = 2, locale: Locale = .current) {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = maxFractionDigits
        nf.usesGroupingSeparator = false
        self.formatter = nf
    }

    private var decimalSeparator: String {
        formatter.decimalSeparator ?? "."
    }

    func parseDecimal(_ s: String) -> Double? {
        guard !s.isEmpty else { return nil }
        return formatter.number(from: s)?.doubleValue
    }

    func sanitizeDecimal(_ s: String) -> String {
        guard !s.isEmpty else { return s }
        let sep = decimalSeparator
        var out = ""
        var seenSep = false
        for ch in s {
            if ch.isNumber {
                out.append(ch)
            } else if String(ch) == sep, !seenSep {
                out.append(ch)
                seenSep = true
            }
        }
        if out.hasPrefix(sep) { out = "0" + out }
        if let range = out.range(of: sep) {
            let fractional = out[range.upperBound...]
            if fractional.count > formatter.maximumFractionDigits {
                let allowed = fractional.prefix(formatter.maximumFractionDigits)
                out = String(out[..<range.upperBound]) + allowed
            }
        }
        return out
    }

    func sanitizeInteger(_ s: String) -> String {
        s.filter { $0.isNumber }
    }
}
