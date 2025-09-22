//
//  ExportCSVButton.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/20/25.
//

import SwiftUI

struct ExportCSVButton: View {
    let entries: [FoodEntry]
    let day: Date

    var body: some View {
        if let url = csvTempFileURL() {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
            }
        } else {
            EmptyView()
        }
    }

    private func csvTempFileURL() -> URL? {
        let cal = Calendar.current
        let header = "date,name,calories"
        let rows = entries
            .sorted { $0.date < $1.date }
            .map { e in
                let d = ISO8601DateFormatter().string(from: e.date)
                let safeName = e.name.replacingOccurrences(of: ",", with: " ")
                return "\(d),\(safeName),\(e.calories)"
            }
        let csv = ([header] + rows).joined(separator: "\n")
        do {
            let dir = FileManager.default.temporaryDirectory
            let stamp = ISO8601DateFormatter().string(from: cal.startOfDay(for: day))
            let url = dir.appendingPathComponent("LeanLog-\(stamp).csv")
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
