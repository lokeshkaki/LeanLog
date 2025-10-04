//
//  FoodSearchView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Simplified - Native keyboard + tap-to-dismiss
//

import SwiftUI
import SwiftData
import UIKit

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
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                                    .lineLimit(2)
                                if let brand = item.brandName {
                                    Text(brand)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if !query.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try another search term.")
                    )
                } else {
                    ContentUnavailableView.search
                }
                
                if let error {
                    Text(error)
                        .foregroundStyle(AppTheme.Colors.destructive)
                        .font(AppTheme.Typography.caption)
                        .padding()
                }
            }
            .screenBackground()
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .tint(AppTheme.Colors.accent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: AppTheme.Icons.close)
                            .imageScale(.medium)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onSubmit(of: .search) {
            performSearchDebounced()
        }
        .onChange(of: query) { _, _ in
            performSearchDebounced()
        }
        .onDisappear {
            searchTask?.cancel()
        }
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

    @FocusState private var focusedField: Field?
    enum Field: Hashable { case quantity }

    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView("Loading nutrition info…")
                        Text("Getting food data from USDA...")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
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
                            Task {
                                await loadDetail()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView("No Data", systemImage: "questionmark.circle")
                }
            }
            .screenBackground()
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.large)
            .modernNavigation()
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: AppTheme.Icons.close)
                            .imageScale(.medium)
                    }
                    .accessibilityLabel("Close")
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
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .padding(.bottom, 4)
                    
                    if let brand = detail.brandOwner {
                        Text(brand)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
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
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                        Spacer()
                        Text(String(format: "%.2f×", qty))
                            .font(AppTheme.Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
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
                            .font(AppTheme.Typography.bodyEmphasized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
                
                if qty != 1.0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your portion:")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                        HStack {
                            Text("\(Int(round(Double(macros.kcal) * qty))) kcal")
                            Text("•")
                            Text("P: \(String(format: "%.1f", macros.protein * qty))g")
                            Text("•")
                            Text("C: \(String(format: "%.1f", macros.carbs * qty))g")
                            Text("•")
                            Text("F: \(String(format: "%.1f", macros.fat * qty))g")
                        }
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
    }
    
    @ViewBuilder
    private func nutritionRow(label: String, value: String, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(isHighlight ? AppTheme.Colors.labelPrimary : AppTheme.Colors.labelSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .fontWeight(isHighlight ? .semibold : .regular)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving food entry: \(error)")
            self.error = "Failed to save food entry"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Locale-aware number IO helper

private struct LocalizedNumberIO {
    private let formatter: NumberFormatter

    init(maxFractionDigits: Int = 2, locale: Locale = .current) {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = maxFractionDigits
        nf.usesGroupingSeparator = false
        self.formatter = nf
    }

    private var decimalSeparator: String {
        formatter.decimalSeparator ?? "."
    }

    func parseDecimal(_ s: String) -> Double? {
        guard !s.isEmpty else { return nil }
        return formatter.number(from: s)?.doubleValue
    }

    func sanitizeDecimal(_ s: String) -> String {
        guard !s.isEmpty else { return s }
        let sep = decimalSeparator
        var out = ""
        var seenSep = false
        for ch in s {
            if ch.isNumber {
                out.append(ch)
            } else if String(ch) == sep, !seenSep {
                out.append(ch)
                seenSep = true
            }
        }
        if out.hasPrefix(sep) { out = "0" + out }
        if let range = out.range(of: sep) {
            let fractional = out[range.upperBound...]
            if fractional.count > formatter.maximumFractionDigits {
                let allowed = fractional.prefix(formatter.maximumFractionDigits)
                out = String(out[..<range.upperBound]) + allowed
            }
        }
        return out
    }

    func sanitizeInteger(_ s: String) -> String {
        s.filter { $0.isNumber }
    }
}
