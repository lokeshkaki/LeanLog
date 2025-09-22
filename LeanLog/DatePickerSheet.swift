//
//  DatePickerSheet.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import SwiftUI

struct DatePickerSheet: View {
    @Binding var selectedDay: Date
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDay, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done", action: onDismiss)
                    }
                }
        }
        .presentationDetents([.medium])
    }
}
