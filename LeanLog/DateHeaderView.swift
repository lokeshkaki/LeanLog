//
//  DateHeaderView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct DateHeaderView: View {
    let selectedDay: Date
    let dayFormatter: DateFormatter
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onDateTap: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onPreviousDay) {
                    Image(systemName: "chevron.left").font(.title3)
                }
                
                Spacer()

                Button(action: onDateTap) {
                    Text(dayFormatter.string(from: selectedDay))
                        .font(.title2).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select date")

                Spacer()
                
                Button(action: onNextDay) {
                    Image(systemName: "chevron.right").font(.title3)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}
