//
//  SettingsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000
    @AppStorage("proteinGoal") private var proteinGoal = 100.0
    @AppStorage("carbGoal") private var carbGoal = 250.0
    @AppStorage("fatGoal") private var fatGoal = 70.0
    
    @FocusState private var isFieldFocused: Bool
    
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
                
                Form {
                    Section {
                        HStack {
                            Label("Calories", systemImage: "flame.fill")
                                .foregroundStyle(.yellow)
                            Spacer()
                            TextField("2000", value: $dailyCalorieGoal, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($isFieldFocused)
                            Text("kcal")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Protein", systemImage: "leaf.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            TextField("100", value: $proteinGoal, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($isFieldFocused)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Carbs", systemImage: "square.stack.3d.up.fill")
                                .foregroundStyle(.indigo)
                            Spacer()
                            TextField("250", value: $carbGoal, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($isFieldFocused)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Fat", systemImage: "drop.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            TextField("70", value: $fatGoal, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($isFieldFocused)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Daily Goals")
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Developer")
                            Spacer()
                            Text("LeanLog Team")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("About")
                    }
                    
                    Section {
                        Button("Export All Data") {
                            // TODO: Implement export functionality
                        }
                        
                        Button("Clear All Data", role: .destructive) {
                            // TODO: Implement clear data functionality
                        }
                    } header: {
                        Text("Data")
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFieldFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
