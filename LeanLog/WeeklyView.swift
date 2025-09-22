//
//  WeeklyView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData
import Charts

struct WeeklyView: View {
    @State private var selectedWeekStart = Calendar.current.startOfDay(for: .now)

    // MARK: - Formatters
    private static let shortDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.calendar = .current
        df.dateFormat = "MMM d"
        return df
    }()

    private var weekRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: selectedWeekStart)?.start ?? selectedWeekStart
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        return (cal.startOfDay(for: start), cal.startOfDay(for: end))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Custom Header with App Title
                HStack {
                    Text("Lean Log")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Week header
                        HStack {
                            Button { changeWeek(by: -1) } label: {
                                Image(systemName: "chevron.left").font(.title3)
                            }
                            
                            Spacer()
                            
                            Text("\(Self.shortDayFormatter.string(from: weekRange.start)) – \(Self.shortDayFormatter.string(from: weekRange.end))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button { changeWeek(by: 1) } label: {
                                Image(systemName: "chevron.right").font(.title3)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // MARK: Weekly chart
                        WeeklySummaryView(referenceDay: selectedWeekStart)
                            .frame(height: 240)
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                            .padding(.horizontal)

                        // MARK: Weekly stats
                        WeeklyStatsView(weekStart: weekRange.start)
                            .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Extra space for tab bar
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func changeWeek(by weeks: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedWeekStart) ?? selectedWeekStart
            selectedWeekStart = Calendar.current.startOfDay(for: selectedWeekStart)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
