//  KeyboardAccessoryStyler.swift
//  LeanLog
//
//  Shared helper to make the native keyboard accessory background appear transparent.
//  Uses view hierarchy introspection (best-effort; not a public API).
//
//  References: ToolbarItemPlacement.keyboard for native toolbar usage [Apple Docs],
//  and practical notes that the accessory background isn't styleable in SwiftUI.
//
//  Toggle usage by just calling: KeyboardAccessoryStyler.shared.makeTransparent()
//  when keyboard shows or frame changes.

import UIKit

final class KeyboardAccessoryStyler {

    static let shared = KeyboardAccessoryStyler()

    private init() {}

    // Attempt to clear accessory/blur backgrounds in the keyboard windows.
    func makeTransparent() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        for window in windows {
            let name = String(describing: type(of: window))
            if name.contains("UIRemoteKeyboardWindow") || name.contains("UITextEffectsWindow") {
                clearIn(view: window)
            }
        }
    }

    private func clearIn(view: UIView) {
        for sub in view.subviews {
            let cls = String(describing: type(of: sub))

            // Clear common blur/backdrop containers used above the keyboard.
            if let ve = sub as? UIVisualEffectView {
                ve.effect = nil
                ve.backgroundColor = .clear
            }
            if cls.contains("Backdrop") || cls.contains("BarBackground") || cls.contains("HostView") {
                sub.backgroundColor = .clear
                sub.alpha = 0
            }

            clearIn(view: sub)
        }
    }
}
