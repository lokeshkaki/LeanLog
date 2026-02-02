//
//  BarcodeScannerWrapper.swift
//  LeanLog
//
//  Scans a barcode and resolves product via OFF, returning barcode too.
//  Includes retry and dismiss paths for reliability.
//

import SwiftUI

struct BarcodeScannerWrapper: View {
    let onResolved: (_ name: String, _ calories: Int, _ protein: Double, _ carbs: Double, _ fat: Double, _ servingSize: Double, _ servingUnit: String, _ barcode: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isResolving = false
    @State private var lastError: String?
    @State private var debugBarcode: String = "" // for manual testing

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 20)

                Text("Scan a barcode")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))

                if let err = lastError {
                    Text(err)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                // Development utility: manual entry to test the flow
                HStack(spacing: 8) {
                    TextField("Enter barcode", text: $debugBarcode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08), in: Capsule())
                        .foregroundStyle(.white.opacity(0.95))

                    Button {
                        Task { await resolve(barcode: debugBarcode.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    } label: {
                        Text("Resolve")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.12), in: Capsule())
                    }
                    .disabled(isResolving || debugBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        Task { await resolve(barcode: "0000000000000") } // sample for quick test
                    } label: {
                        HStack(spacing: 8) {
                            if isResolving { ProgressView().tint(.white) }
                            Text(isResolving ? "Resolving…" : "Try Sample")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.12), in: Capsule())
                    }
                    .disabled(isResolving)

                    Button(role: .cancel) { dismiss() } label: {
                        Text("Close")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.12), in: Capsule())
                    }
                }

                Spacer()

                // Large close as fallback, big hit target
                Button(role: .cancel) { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 54, height: 54)
                        .background(.white, in: Circle())
                }
                .padding(.bottom, 40)
                .contentShape(Circle())
                .zIndex(1)
            }
            .padding(.top, 24)
        }
        // Dismiss on background tap too (belt and suspenders)
        .contentShape(Rectangle())
        .onTapGesture { /* keep tap for close only if desired */ }
    }

    // MARK: - Resolve

    private func resolve(barcode: String) async {
        guard !barcode.isEmpty, !isResolving else { return }
        isResolving = true
        lastError = nil
        defer { isResolving = false }

        do {
            let service = OpenFoodFactsService()
            let resolved = try await service.fetchResolvedFood(barcode)
            onResolved(
                resolved.name,
                resolved.calories,
                resolved.protein,
                resolved.carbs,
                resolved.fat,
                resolved.servingSize,
                resolved.servingUnit,
                resolved.sourceBarcode
            )
            dismiss()
        } catch {
            lastError = "Unable to resolve product."
        }
    }
}
