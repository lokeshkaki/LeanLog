//
//  EditFoodView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var entry: FoodEntry
    
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var servingSize: String
    @State private var servingUnit: String
    @State private var selectedDate: Date
    @State private var showingDeleteAlert = false
    
    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case name, calories, protein, carbs, fat, servingSize, servingUnit
    }
    
    init(entry: FoodEntry) {
        self.entry = entry
        
        // Initialize @State properties from the entry
        self._name = State(initialValue: entry.name)
        self._calories = State(initialValue: String(entry.calories))
        
        // Handle optional values properly
        let proteinValue = entry.protein ?? 0
        let carbsValue = entry.carbs ?? 0
        let fatValue = entry.fat ?? 0
        
        self._protein = State(initialValue: proteinValue > 0 ? String(format: "%.1f", proteinValue).replacingOccurrences(of: ".0", with: "") : "")
        self._carbs = State(initialValue: carbsValue > 0 ? String(format: "%.1f", carbsValue).replacingOccurrences(of: ".0", with: "") : "")
        self._fat = State(initialValue: fatValue > 0 ? String(format: "%.1f", fatValue).replacingOccurrences(of: ".0", with: "") : "")
        
        self._servingSize = State(initialValue: entry.servingSize != nil ? String(format: "%.1f", entry.servingSize!).replacingOccurrences(of: ".0", with: "") : "")
        self._servingUnit = State(initialValue: entry.servingUnit ?? "")
        self._selectedDate = State(initialValue: entry.date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food name", text: $name)
                        .focused($focusedField, equals: .name)
                    
                    HStack {
                        TextField("Serving size", text: $servingSize)
                            .focused($focusedField, equals: .servingSize)
                            .keyboardType(.decimalPad)
                        TextField("Unit (e.g., cup, oz)", text: $servingUnit)
                            .focused($focusedField, equals: .servingUnit)
                    }
                    
                    if let source = entry.source {
                        HStack {
                            Text("Source")
                            Spacer()
                            Text(source)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                
                Section("Nutrition (per serving)") {
                    HStack {
                        Label("Calories", systemImage: "flame.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        TextField("0", text: $calories)
                            .focused($focusedField, equals: .calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Protein", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        TextField("0", text: $protein)
                            .focused($focusedField, equals: .protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Carbs", systemImage: "square.stack.3d.up.fill")
                            .foregroundStyle(.indigo)
                        Spacer()
                        TextField("0", text: $carbs)
                            .focused($focusedField, equals: .carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Fat", systemImage: "drop.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        TextField("0", text: $fat)
                            .focused($focusedField, equals: .fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Log Details") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
                
                // Calculation preview - only show if there are macro values
                if !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty {
                    Section("Calculated Values") {
                        let caloriesFromMacros = calculateCaloriesFromMacros()
                        let enteredCalories = Int(calories) ?? 0
                        
                        HStack {
                            Text("Calories from macros")
                            Spacer()
                            Text("\(caloriesFromMacros) kcal")
                                .foregroundStyle(abs(caloriesFromMacros - enteredCalories) > 10 ? .orange : .secondary)
                        }
                        .font(.caption)
                        
                        if abs(caloriesFromMacros - enteredCalories) > 10 && enteredCalories > 0 {
                            Text("⚠️ Calorie mismatch detected")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Section {
                    Button("Delete Entry", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty || calories.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this food entry? This action cannot be undone.")
            }
        }
    }
    
    private func calculateCaloriesFromMacros() -> Int {
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }
    
    private func saveChanges() {
        entry.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.calories = Int(calories) ?? 0
        entry.protein = protein.isEmpty ? 0 : (Double(protein) ?? 0)
        entry.carbs = carbs.isEmpty ? 0 : (Double(carbs) ?? 0)
        entry.fat = fat.isEmpty ? 0 : (Double(fat) ?? 0)
        entry.servingSize = servingSize.isEmpty ? nil : Double(servingSize)
        entry.servingUnit = servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.date = Calendar.current.startOfDay(for: selectedDate)
        // Don't update timestamp when editing - keep original log time
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    private func deleteEntry() {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}
