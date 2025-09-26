//
//  KeyboardAccessoryConfig.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/26/25.
//

import SwiftUI

struct KeyboardAccessoryConfig {
    let showPrevious: Bool
    let showNext: Bool
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let onDone: () -> Void

    static func done(_ onDone: @escaping () -> Void) -> KeyboardAccessoryConfig {
        .init(showPrevious: false, showNext: false, onPrevious: nil, onNext: nil, onDone: onDone)
    }
}

struct KeyboardAccessoryBar: View {
    let config: KeyboardAccessoryConfig

    var body: some View {
        HStack {
            if config.showPrevious, let onPrev = config.onPrevious {
                Button("Previous", action: onPrev)
                    .buttonStyle(AccessoryCapsuleStyle(disabled: false))
            }
            if config.showNext, let onNext = config.onNext {
                Button("Next", action: onNext)
                    .buttonStyle(AccessoryCapsuleStyle(disabled: false))
            }
            Spacer(minLength: 16)
            Button("Done", action: config.onDone)
                .buttonStyle(AccessoryCapsuleStyle(disabled: false, prominent: true))
        }
        .padding(.horizontal, AppTheme.Spacing.screenPadding)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

private struct AccessoryCapsuleStyle: ButtonStyle {
    var disabled: Bool
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let backgroundStyle: AnyShapeStyle = prominent
            ? AnyShapeStyle(AppTheme.Colors.accentGradient)
            : AnyShapeStyle(AppTheme.Colors.input.opacity(disabled ? 0.6 : 1))
        return configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(prominent ? Color.white : AppTheme.Colors.labelPrimary.opacity(disabled ? 0.5 : 1))
            .background(Capsule().fill(backgroundStyle))
            .overlay(Capsule().strokeBorder(AppTheme.Colors.subtleStroke, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct KeyboardAccessoryModifier<F: Hashable>: ViewModifier {
    @Binding var focusedField: F?
    let match: F
    let config: KeyboardAccessoryConfig

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            if focusedField == match {
                KeyboardAccessoryBar(config: config)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: focusedField == match)
            }
        }
    }
}

extension View {
    func keyboardAccessory<F: Hashable>(
        focusedField: Binding<F?>,
        equals match: F,
        config: KeyboardAccessoryConfig
    ) -> some View {
        modifier(KeyboardAccessoryModifier(focusedField: focusedField, match: match, config: config))
    }
}

func binding<F>(_ focusBinding: FocusState<F?>.Binding) -> Binding<F?> {
    Binding<F?>(
        get: { focusBinding.wrappedValue },
        set: { focusBinding.wrappedValue = $0 }
    )
}
