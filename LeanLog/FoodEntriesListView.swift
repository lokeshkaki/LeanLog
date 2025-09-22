//
//  FoodEntriesListView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct FoodEntriesListView: View {
    let entries: [FoodEntry]
    let onEntryTap: (FoodEntry) -> Void
    let onEntryDelete: (FoodEntry) -> Void
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                VStack(spacing: 0) {
                    // Add time gap indicator between entries
                    if index > 0 {
                        TimeGapIndicator(
                            previousEntry: entries[index - 1],
                            currentEntry: entry
                        )
                    }
                    
                    FoodEntryRow(
                        entry: entry,
                        timeFormatter: Self.timeFormatter,
                        onTap: { onEntryTap(entry) }
                    )
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            onEntryDelete(entry)
                        }
                    }
                }
            }
            
            if entries.isEmpty {
                EmptyStateView()
            }
        }
    }
}

struct TimeGapIndicator: View {
    let previousEntry: FoodEntry
    let currentEntry: FoodEntry
    
    private var timeGap: TimeInterval {
        previousEntry.timestamp.timeIntervalSince(currentEntry.timestamp)
    }
    
    private var gapText: String {
        let totalSeconds = Int(timeGap)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours >= 1 {
            if minutes == 0 {
                return "\(hours)h later"
            } else {
                return "\(hours)h \(minutes)m later"
            }
        } else if minutes >= 1 {
            return "\(minutes)m later"
        } else {
            return "shortly after"
        }
    }
    
    private var shouldShowGap: Bool {
        timeGap >= 300 // Show gap if more than 5 minutes
    }
    
    var body: some View {
        if shouldShowGap {
            VStack(spacing: 8) {
                Spacer()
                    .frame(height: 16)
                
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 40)
                    
                    Text(gapText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .systemBackground))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 40)
                }
                
                Spacer()
                    .frame(height: 16)
            }
        } else {
            Spacer()
                .frame(height: 12)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No food logged today")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Tap the + button to add your first meal")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}
