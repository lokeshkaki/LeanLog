//
//  HorizontalSwipeModifier.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct HorizontalSwipeModifier: ViewModifier {
    @Binding var anchorDate: Date
    let stepDays: Int
    let threshold: CGFloat = 40

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let dx = value.translation.width
                    guard abs(dx) > threshold else { return }
                    withAnimation(.easeInOut) {
                        let delta = dx < 0 ? stepDays : -stepDays
                        if let next = Calendar.current.date(byAdding: .day, value: delta, to: anchorDate) {
                            anchorDate = next
                        }
                    }
                }
        )
    }
}

extension View {
    func swipeChangeDate(anchorDate: Binding<Date>, stepDays: Int) -> some View {
        modifier(HorizontalSwipeModifier(anchorDate: anchorDate, stepDays: stepDays))
    }
}
