//
//  HomeView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000
    @AppStorage("proteinGoal") private var proteinGoal = 100.0
    @AppStorage("carbGoal") private var carbGoal = 250.0
    @AppStorage("fatGoal") private var fatGoal = 70.0

    // MARK: - State
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @State private var showingAdd = false
    @State private var showingSearch = false
    @State private var editingEntry: FoodEntry?
    @State private var showDatePicker = false

    // MARK: - Query
    @Query(sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)])
    private var allEntries: [FoodEntry]

    // MARK: - Formatters
    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.calendar = .current
        df.dateFormat = "EEE, MMM d, yyyy"
        return df
    }()

    // MARK: - Derived
    var entries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }

    var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        entries.reduce(0) { $0 + ($1.protein ?? 0) }
    }
    
    var totalCarbs: Double {
        entries.reduce(0) { $0 + ($1.carbs ?? 0) }
    }
    
    var totalFat: Double {
        entries.reduce(0) { $0 + ($1.fat ?? 0) }
    }

    // MARK: - Body
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
                    
                    HStack(spacing: 16) {
                        Button { showingSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                        }
                        ExportCSVButton(entries: entries, day: selectedDay)
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 20) {
                        DateHeaderView(
                            selectedDay: selectedDay,
                            dayFormatter: Self.dayFormatter,
                            onPreviousDay: { changeDay(by: -1) },
                            onNextDay: { changeDay(by: 1) },
                            onDateTap: { showDatePicker = true }
                        )
                        
                        MacroGoalsView(
                            totalCalories: totalCalories,
                            totalProtein: totalProtein,
                            totalCarbs: totalCarbs,
                            totalFat: totalFat,
                            calorieGoal: dailyCalorieGoal,
                            proteinGoal: proteinGoal,
                            carbGoal: carbGoal,
                            fatGoal: fatGoal
                        )
                        .padding(.horizontal)
                        
                        // MARK: Food Logs Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Food Logs")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            FoodEntriesListView(
                                entries: entries,
                                onEntryTap: { entry in editingEntry = entry },
                                onEntryDelete: deleteEntry
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDay: $selectedDay, onDismiss: { showDatePicker = false })
            }
            .sheet(isPresented: $showingAdd) {
                AddFoodView(defaultDate: selectedDay)
            }
            .sheet(isPresented: $showingSearch) {
                FoodSearchView()
            }
            .sheet(item: $editingEntry) { entry in
                EditFoodView(entry: entry)
            }
        }
    }

    // MARK: - Actions
    private func changeDay(by days: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedDay = Calendar.current.date(byAdding: .day, value: days, to: selectedDay) ?? selectedDay
            selectedDay = Calendar.current.startOfDay(for: selectedDay)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}
