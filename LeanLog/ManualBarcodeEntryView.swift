//
//  ManualBarcodeEntryView.swift
//  LeanLog
//

import SwiftUI

struct ManualBarcodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""

    let onLookup: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                Text("Enter the barcode number")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)

                TextField("e.g. 012345678905", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .modernInput()
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)

                Button {
                    let digits = code.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    guard !digits.isEmpty else { return }
                    onLookup(digits)
                } label: {
                    Text("Lookup Barcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.screenPadding)

                Spacer()
            }
            .padding(.top, AppTheme.Spacing.lg)
            .screenBackground()
            .navigationTitle("Manual Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
