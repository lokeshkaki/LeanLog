//
//  BarcodeScannerWrapper.swift
//  LeanLog
//
//  OFF-backed scanner wrapper: resolves barcode → OFFResolvedFood → FoodEntry.
//

import SwiftUI

struct BarcodeScannerWrapper: View {
    @Environment(\.dismiss) private var dismiss

    // The wrapper returns resolved values directly for constructing FoodEntry.
    let onFoodFound: (String, Int, Double, Double, Double, Double, String) -> Void

    @State private var showingManualEntry = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let offService = OpenFoodFactsService()

    var body: some View {
        ZStack {
            BarcodeScannerRepresentable(
                onCodeScanned: { code in Task { await lookupBarcode(code) } },
                onManual: { showingManualEntry = true },
                onDismiss: { dismiss() }
            )
            .ignoresSafeArea()

            if isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView().scaleEffect(1.5).tint(.white)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBarcodeEntryView { code in
                Task { await lookupBarcode(code) }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func lookupBarcode(_ code: String) async {
        await MainActor.run { isLoading = true }
        do {
            let resolved = try await offService.fetchResolvedFood(code)
            await MainActor.run {
                isLoading = false
                onFoodFound(
                    resolved.name,
                    resolved.calories,
                    resolved.protein,
                    resolved.carbs,
                    resolved.fat,
                    resolved.servingSize,
                    resolved.servingUnit
                )
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Product not found: \(code)"
            }
        }
    }
}

struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onManual: () -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onCodeScanned = onCodeScanned
        vc.onManualTap = onManual
        vc.onCloseTap = onDismiss
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}
