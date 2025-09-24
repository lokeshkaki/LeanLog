//
//  AddIngredientView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/22/25.
//

import SwiftUI
import SwiftData

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onIngredientAdded: (MealIngredient) -> Void
    
    @State private var selectedTab = 0
    @State private var quantity: Double = 1.0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                SearchIngredientsView(quantity: $quantity, onIngredientAdded: onIngredientAdded)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                ManualIngredientView(quantity: $quantity, onIngredientAdded: onIngredientAdded)
                    .tabItem {
                        Label("Manual", systemImage: "square.and.pencil")
                    }
                    .tag(1)
                
                RecentIngredientsView(quantity: $quantity, onIngredientAdded: onIngredientAdded)
                    .tabItem {
                        Label("Recent", systemImage: "clock")
                    }
                    .tag(2)
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// Search ingredients using existing USDA search
struct SearchIngredientsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var quantity: Double
    let onIngredientAdded: (MealIngredient) -> Void
    
    @State private var query = ""
    @State private var results: [FDCSearchFood] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var searchTask: Task<Void, Never>?
    
    private let usda = USDAService(apiKey: Secrets.usdaApiKey)
    
    var body: some View {
        VStack(spacing: 0) {
            quantitySelector
            
            Divider()
            
            Group {
                if isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !results.isEmpty {
                    List(results) { item in
                        Button(action: {
                            Task { await selectSearchResult(item) }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.description)
                                    .font(.body)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)
                                
                                if let brand = item.brandName {
                                    Text(brand)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else if !query.isEmpty {
                    ContentUnavailableView("No results", systemImage: "magnifyingglass")
                } else {
                    ContentUnavailableView.search
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: query) { _, newValue in
            performSearchDebounced()
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
    
    private var quantitySelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quantity:")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.2f", quantity))×")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            HStack(spacing: 20) {
                Button("-") {
                    quantity = max(0.1, quantity - 0.25)
                }
                .buttonStyle(.bordered)
                .disabled(quantity <= 0.1)
                
                Slider(value: $quantity, in: 0.1...10, step: 0.25)
                
                Button("+") {
                    quantity = min(10, quantity + 0.25)
                }
                .buttonStyle(.bordered)
                .disabled(quantity >= 10)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    private func performSearchDebounced() {
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedQuery.count >= 2 else {
            results = []
            error = nil
            isLoading = false
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(trimmedQuery)
        }
    }
    
    @MainActor
    private func performSearch(_ term: String) async {
        isLoading = true
        error = nil
        
        do {
            let searchResults = try await usda.searchFoods(query: term, pageSize: 20)
            
            let currentTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard term == currentTerm else { return }
            
            results = searchResults
            error = nil
        } catch {
            let currentTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard term == currentTerm else { return }
            
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            results = []
        }
        
        isLoading = false
    }
    
    private func selectSearchResult(_ item: FDCSearchFood) async {
        do {
            let detail = try await usda.fetchFoodDetail(fdcId: item.fdcId)
            let macros = detail.extractMacros()
            
            let ingredient = MealIngredient(
                name: detail.description ?? item.description,
                quantity: quantity,
                calories: macros.kcal,
                protein: macros.protein,
                carbs: macros.carbs,
                fat: macros.fat,
                servingSize: detail.actualServingSize,
                servingUnit: detail.actualServingUnit,
                source: "USDA"
            )
            
            onIngredientAdded(ingredient)
            dismiss()
        } catch {
            print("Error fetching ingredient details: \(error)")
        }
    }
}

// Manual ingredient entry
struct ManualIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var quantity: Double
    let onIngredientAdded: (MealIngredient) -> Void
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, calories, protein, carbs, fat, servingSize, servingUnit
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.isEmpty &&
        Int(calories) != nil
    }
    
    var body: some View {
        Form {
            Section("Ingredient Details") {
                TextField("Ingredient name", text: $name)
                    .focused($focusedField, equals: .name)
                
                HStack {
                    TextField("Serving size", text: $servingSize)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .servingSize)
                    TextField("Unit", text: $servingUnit)
                        .focused($focusedField, equals: .servingUnit)
                }
            }
            
            Section("Nutrition (per serving)") {
                HStack {
                    Label("Calories", systemImage: "flame.fill")
                        .foregroundStyle(AppTheme.calories)
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
                        .foregroundStyle(AppTheme.protein)
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
                        .foregroundStyle(AppTheme.carbs)
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
                        .foregroundStyle(AppTheme.fat)
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
            
            Section("Quantity") {
                HStack {
                    Text("Amount:")
                    Spacer()
                    Text("\(String(format: "%.2f", quantity))× servings")
                        .fontWeight(.semibold)
                }
                
                Stepper("", value: $quantity, in: 0.1...10, step: 0.25)
                    .labelsHidden()
            }
            
            Section {
                Button("Add Ingredient") {
                    addIngredient()
                }
                .disabled(!isValid)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    private func addIngredient() {
        let ingredient = MealIngredient(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            calories: Int(calories) ?? 0,
            protein: protein.isEmpty ? nil : Double(protein),
            carbs: carbs.isEmpty ? nil : Double(carbs),
            fat: fat.isEmpty ? nil : Double(fat),
            servingSize: servingSize.isEmpty ? nil : Double(servingSize),
            servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Manual"
        )
        
        onIngredientAdded(ingredient)
        dismiss()
    }
}

// Recent ingredients from food logs
struct RecentIngredientsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var quantity: Double
    let onIngredientAdded: (MealIngredient) -> Void
    
    // Calculate the date 30 days ago outside of the predicate
    private var thirtyDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }
    
    @Query(sort: [SortDescriptor(\FoodEntry.timestamp, order: .reverse)])
    private var allFoodEntries: [FoodEntry]
    
    private var recentFoods: [FoodEntry] {
        allFoodEntries.filter { entry in
            entry.timestamp >= thirtyDaysAgo
        }
    }
    
    private var uniqueRecentFoods: [FoodEntry] {
        var seen = Set<String>()
        return recentFoods.compactMap { entry in
            let key = entry.name.lowercased()
            if seen.contains(key) {
                return nil
            } else {
                seen.insert(key)
                return entry
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Quantity:")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.2f", quantity))×")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            
            Stepper("", value: $quantity, in: 0.1...10, step: 0.25)
                .padding(.horizontal)
                .labelsHidden()
            
            Divider()
            
            if uniqueRecentFoods.isEmpty {
                ContentUnavailableView(
                    "No Recent Foods",
                    systemImage: "clock",
                    description: Text("Foods you've logged in the last 30 days will appear here")
                )
            } else {
                List(uniqueRecentFoods.prefix(20), id: \.id) { entry in
                    Button(action: { selectRecentFood(entry) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            HStack {
                                Text("\(entry.calories) kcal")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.calories)
                                
                                if let protein = entry.protein, protein > 0 {
                                    Text("• P: \(String(format: "%.1f", protein))g")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let source = entry.source {
                                    Text("• \(source)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func selectRecentFood(_ entry: FoodEntry) {
        let ingredient = MealIngredient(
            name: entry.name,
            quantity: quantity,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            servingSize: entry.servingSize,
            servingUnit: entry.servingUnit,
            source: entry.source
        )
        
        onIngredientAdded(ingredient)
        dismiss()
    }
}
