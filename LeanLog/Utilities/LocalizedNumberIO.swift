//
//  LocalizedNumberIO.swift
//  LeanLog
//

import Foundation

struct LocalizedNumberIO: Sendable {
    let maxFractionDigits: Int

    private var formatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.locale = .current
        nf.generatesDecimalNumbers = false
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = maxFractionDigits
        return nf
    }

    private var decimalSeparator: String {
        formatter.decimalSeparator ?? Locale.current.decimalSeparator ?? "."
    }

    // Keep only digits and at most one decimal separator; clamp fraction length.
    func sanitizeDecimal(_ input: String) -> String {
        var allowed = CharacterSet.decimalDigits
        allowed.insert(charactersIn: decimalSeparator)

        let filtered = input.unicodeScalars.filter { allowed.contains($0) }
        var s = String(String.UnicodeScalarView(filtered))

        // Normalize multiple separators -> keep first
        if s.components(separatedBy: decimalSeparator).count > 2 {
            var parts = s.components(separatedBy: decimalSeparator)
            let head = parts.removeFirst()
            s = head + decimalSeparator + parts.joined().replacingOccurrences(of: decimalSeparator, with: "")
        }

        // Enforce max fraction digits
        if let range = s.range(of: decimalSeparator) {
            let frac = s[range.upperBound...]
            if frac.count > maxFractionDigits {
                let trimmed = frac.prefix(maxFractionDigits)
                s = String(s[..<range.upperBound]) + trimmed
            }
        }
        // Remove leading zeros like "00" → "0", but keep "0." intact
        if s.hasPrefix("00") {
            while s.hasPrefix("00") { s.removeFirst() }
            if s.isEmpty { s = "0" }
        }
        return s
    }

    // Keep only digits, drop everything else.
    func sanitizeInteger(_ input: String) -> String {
        let digits = input.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        let s = String(String.UnicodeScalarView(digits))
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Parse respecting locale; also try a dot-fallback for robustness.
    func parseDouble(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if let n = formatter.number(from: trimmed) {
            return n.doubleValue
        }
        // Fallback: replace common alternate separator and retry
        let alt: String = (decimalSeparator == ".") ? "," : "."
        if trimmed.contains(alt) {
            let swapped = trimmed.replacingOccurrences(of: alt, with: decimalSeparator)
            if let n = formatter.number(from: swapped) {
                return n.doubleValue
            }
        }
        // Last resort plain Double init
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
