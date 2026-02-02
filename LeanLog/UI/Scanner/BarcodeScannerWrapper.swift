//
//  BarcodeScannerWrapper.swift
//  LeanLog
//
//  SwiftUI bridge around BarcodeScannerViewController (AVFoundation)
//  Resolves scanned barcode via OpenFoodFactsService, then returns core fields + barcode.
//

import SwiftUI

struct BarcodeScannerWrapper: View {
    let onResolved: (_ name: String,
                     _ calories: Int,
                     _ protein: Double,
                     _ carbs: Double,
                     _ fat: Double,
                     _ servingSize: Double,
                     _ servingUnit: String,
                     _ barcode: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isResolving = false
    @State private var lastError: String?

    var body: some View {
        ZStack {
            ScannerHost(
                onCodeScanned: { code in
                    Task { await resolve(barcode: code) }
                },
                onManualTap: {
                    dismiss()
                },
                onCloseTap: {
                    dismiss()
                }
            )
            if isResolving || lastError != nil {
                VStack(spacing: 12) {
                    if isResolving {
                        ProgressView().tint(.white)
                        Text("Resolving…")
                            .foregroundStyle(.white)
                            .font(.callout.weight(.semibold))
                    }
                    if let err = lastError {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                }
                .padding(.bottom, 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Resolve via OFF

    private func resolve(barcode: String) async {
        guard !barcode.isEmpty, !isResolving else { return }
        isResolving = true
        lastError = nil
        defer { isResolving = false }

        do {
            let service = OpenFoodFactsService()
            let r = try await service.fetchResolvedFood(barcode)

            onResolved(
                r.name,
                r.calories,
                r.protein,
                r.carbs,
                r.fat,
                r.servingSize,
                r.servingUnit,
                r.sourceBarcode
            )
            dismiss()
        } catch {
            lastError = "Unable to resolve product."
        }
    }
}

// MARK: - UIKit host

private struct ScannerHost: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onManualTap: () -> Void
    let onCloseTap: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onCodeScanned = { code in onCodeScanned(code) }
        vc.onManualTap = { onManualTap() }
        vc.onCloseTap = { onCloseTap() }
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // Nothing to update live.
    }
}
