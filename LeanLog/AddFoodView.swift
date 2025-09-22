//
//  AddFoodView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let defaultDate: Date
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = ""
    @State private var selectedDate: Date
    
    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case name, calories, protein, carbs, fat, servingSize, servingUnit
    }
    
    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        self._selectedDate = State(initialValue: Calendar.current.startOfDay(for: defaultDate))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food name", text: $name)
                        .focused($focusedField, equals: .name)
                    
                    HStack {
                        TextField("Serving size", text: $servingSize)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .servingSize)
                        TextField("Unit (e.g., cup, oz)", text: $servingUnit)
                            .focused($focusedField, equals: .servingUnit)
                    }
                }
                
                Section("Nutrition (per serving)") {
                    HStack {
                        Label("Calories", systemImage: "flame.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .calories)
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
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .protein)
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
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .carbs)
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
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .fat)
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
                
                // Quick calculation preview
                if !calories.isEmpty || !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty {
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
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveFood() }
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
        }
    }
    
    private func calculateCaloriesFromMacros() -> Int {
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        return Int(round((p * 4) + (c * 4) + (f * 9)))
    }
    
    private func saveFood() {
        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            servingSize: servingSize.isEmpty ? nil : Double(servingSize),
            servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Calendar.current.startOfDay(for: selectedDate),
            timestamp: Date(),  // Current timestamp
            source: "Manual",
            externalId: nil
        )
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving food entry: \(error)")
        }
    }
}
