//
//  FoodSearchView.swift
//  LeanLog
//
//  Simplified: Native keyboard + tap-to-dismiss
//

import SwiftUI
import SwiftData
import UIKit

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var query = ""
    // Use the same type used elsewhere for USDA search results
    @State private var results: [FDCSearchFood] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?

    // Use shared number IO helper
    private let numberIO = LocalizedNumberIO(maxFractionDigits: 2)

    private let usda = USDAService(apiKey: Secrets.usdaApiKey)

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                        searchCard.modernCard()
                        resultsList
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.xl)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Search Foods")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppTheme.Icons.close).imageScale(.medium)
                    }
                }
            }
        }
        .onDisappear { searchTask?.cancel() }
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Search USDA")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.labelPrimary)

            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: AppTheme.Icons.search)
                    .foregroundStyle(AppTheme.Colors.labelTertiary)
                TextField("Search foods…", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .onChange(of: query) { _, _ in debounceSearch() }
            }
            .modernField()

            if searching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }

    private var resultsList: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Provide an id to ForEach to avoid type inference issues if the item type isn’t Identifiable at compile time
            ForEach(results, id: \.fdcId) { item in
                Button { Task { await selectItem(item) } } label: {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
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
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                    }
                    .padding(AppTheme.Spacing.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .fill(AppTheme.Colors.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.cardStrokeGradient, lineWidth: 1)
                            }
                    )
                }
                .buttonStyle(.plain)
            }

            if !query.isEmpty && results.isEmpty && !searching {
                ContentUnavailableView("No results", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func debounceSearch() {
        searchTask?.cancel()
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else {
            results = []
            searching = false
            return
        }
        searchTask = Task { @MainActor in
            searching = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(term)
        }
    }

    @MainActor
    private func runSearch(_ term: String) async {
        do {
            // Use the existing searchFoods API that returns FDCSearchFood
            results = try await usda.searchFoods(query: term, pageSize: 30)
            searching = false
        } catch {
            results = []
            searching = false
        }
    }

    @MainActor
    private func selectItem(_ item: FDCSearchFood) async {
        do {
            let detail = try await usda.fetchFoodDetail(fdcId: item.fdcId)
            let m = detail.extractMacros()
            let now = Date()
            let day = Calendar.current.startOfDay(for: now)

            let entry = FoodEntry(
                name: detail.description ?? item.description,
                calories: Int(m.kcal),
                servingSize: detail.actualServingSize,
                servingUnit: detail.actualServingUnit,
                date: day,
                timestamp: now,
                source: "USDA",
                externalId: String(item.fdcId),
                protein: m.protein,
                carbs: m.carbs,
                fat: m.fat
            )
            modelContext.insert(entry)
            try? modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("USDA fetch error: \(error)")
        }
    }
}
