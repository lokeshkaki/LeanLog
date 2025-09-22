//
//  FoodSearchView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var query = ""
    @State private var results: [FDCSearchFood] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var searchTask: Task<Void, Never>?

    private let usda = USDAService(apiKey: Secrets.usdaApiKey)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Searching…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !results.isEmpty {
                    List(results) { item in
                        NavigationLink {
                            FoodDetailResultView(fdcId: item.fdcId, usda: usda)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.description)
                                    .font(.body)
                                    .lineLimit(2)
                                if let brand = item.brandName {
                                    Text(brand)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if !query.isEmpty {
                    ContentUnavailableView("No results", systemImage: "magnifyingglass", description: Text("Try another search term."))
                } else {
                    ContentUnavailableView.search
                }
                
                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline) // Prevents navigation bar resizing
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .onSubmit(of: .search) {
            // Trigger search on submit/return
            performSearchDebounced()
        }
        .onChange(of: query) { _, newValue in
            // Debounce search to avoid excessive API calls
            performSearchDebounced()
        }
        .onDisappear {
            // Cancel any pending search when view disappears
            searchTask?.cancel()
        }
    }

    private func performSearchDebounced() {
        // Cancel previous search task
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedQuery.count >= 2 else {
            results = []
            error = nil
            isLoading = false
            return
        }
        
        // Create new search task with delay
        searchTask = Task {
            // Wait 300ms before searching (debounce)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if task was cancelled
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
            
            // Check if this is still the current search
            let currentTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard term == currentTerm else { return }
            
            results = searchResults
            error = nil
        } catch {
            // Only show error if this is still the current search
            let currentTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard term == currentTerm else { return }
            
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            results = []
        }
        
        isLoading = false
    }
}

struct FoodDetailResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let fdcId: Int
    let usda: USDAService

    @State private var detail: FDCFoodDetail?
    @State private var qty: Double = 1
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView("Loading nutrition info…")
                        Text("Getting food data from USDA...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail = detail {
                    foodDetailsForm(for: detail)
                } else if let error = error {
                    ContentUnavailableView {
                        Label("Error Loading Food", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await loadDetail() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView("No Data", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            await loadDetail()
        }
        .refreshable {
            await loadDetail()
        }
    }
    
    @ViewBuilder
    private func foodDetailsForm(for detail: FDCFoodDetail) -> some View {
        let macros = detail.extractMacros()
        
        Form {
            Section("Nutrition Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.description ?? "Food")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    if let brand = detail.brandOwner {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                nutritionRow(label: "Calories", value: "\(macros.kcal) kcal", isHighlight: true)
                nutritionRow(label: "Protein", value: String(format: "%.1f g", macros.protein))
                nutritionRow(label: "Carbs", value: String(format: "%.1f g", macros.carbs))
                nutritionRow(label: "Fat", value: String(format: "%.1f g", macros.fat))
                
                if let servingSize = detail.actualServingSize,
                   let servingUnit = detail.actualServingUnit {
                    nutritionRow(label: "Serving", value: "\(Int(servingSize)) \(servingUnit)")
                }
            }
            
            Section("Add to Log") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quantity:")
                        Spacer()
                        Text(String(format: "%.2f×", qty))
                            .fontWeight(.medium)
                    }
                    
                    Stepper("", value: $qty, in: 0.25...10, step: 0.25)
                        .labelsHidden()
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
                
                Button(action: { logFood(detail, macros: macros) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log to LeanLog")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                
                // Show calculated values
                if qty != 1.0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your portion:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("\(Int(round(Double(macros.kcal) * qty))) kcal")
                            Text("•")
                            Text("P: \(String(format: "%.1f", macros.protein * qty))g")
                            Text("•")
                            Text("C: \(String(format: "%.1f", macros.carbs * qty))g")
                            Text("•")
                            Text("F: \(String(format: "%.1f", macros.fat * qty))g")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func nutritionRow(label: String, value: String, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(isHighlight ? .primary : .secondary)
            Spacer()
            Text(value)
                .fontWeight(isHighlight ? .semibold : .regular)
                .foregroundStyle(isHighlight ? .primary : .primary)
        }
    }

    @MainActor
    private func loadDetail() async {
        isLoading = true
        error = nil
        detail = nil
        
        do {
            print("Loading food detail for ID: \(fdcId)")
            let foodDetail = try await usda.fetchFoodDetail(fdcId: fdcId)
            print("Successfully loaded food: \(foodDetail.description ?? "Unknown")")
            
            detail = foodDetail
            error = nil
        } catch {
            print("Error loading food detail: \(error)")
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            detail = nil
        }
        
        isLoading = false
    }

    private func logFood(_ detail: FDCFoodDetail, macros: Macros) {
        let scale = qty
        let entry = FoodEntry(
            name: detail.description ?? "Food",
            calories: Int(round(Double(macros.kcal) * scale)),
            protein: macros.protein * scale,
            carbs: macros.carbs * scale,
            fat: macros.fat * scale,
            servingSize: detail.actualServingSize,
            servingUnit: detail.actualServingUnit,
            date: Calendar.current.startOfDay(for: selectedDate),
            source: "FDC",
            externalId: String(fdcId)
        )
        
        do {
            modelContext.insert(entry)
            try modelContext.save()
            print("Successfully logged food: \(entry.name)")
            dismiss()
        } catch {
            print("Error saving food entry: \(error)")
            self.error = "Failed to save food entry"
        }
    }
}
