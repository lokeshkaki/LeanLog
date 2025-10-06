//
//  OpenFoodFactsService.swift
//  LeanLog
//
//  Internal access across the module. Raw OFF models remain internal,
//  and the high-level fetchResolvedFood is the API used by the scanner.
//

import Foundation

// MARK: - Public-facing within module

struct OFFResolvedFood: Sendable {
    let name: String
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
    let servingUnit: String
    let sourceBarcode: String
}

// MARK: - Wire models (exact OFF mapping)

struct OFFProductResponse: Decodable {
    let status: Int
    let code: String?
    let product: OFFProduct?
}

struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case nutriments
    }
}

struct OFFNutriments: Decodable {
    // Calories
    let energyKcal: Double?
    let energyKcal100g: Double?
    let energyKcalServing: Double?

    // Protein
    let proteins: Double?
    let proteins100g: Double?
    let proteinsServing: Double?

    // Carbs
    let carbohydrates: Double?
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?

    // Fat
    let fat: Double?
    let fat100g: Double?
    let fatServing: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal         = "energy-kcal"
        case energyKcal100g     = "energy-kcal_100g"
        case energyKcalServing  = "energy-kcal_serving"

        case proteins
        case proteins100g       = "proteins_100g"
        case proteinsServing    = "proteins_serving"

        case carbohydrates
        case carbohydrates100g  = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"

        case fat
        case fat100g            = "fat_100g"
        case fatServing         = "fat_serving"
    }
}

// MARK: - Errors

enum OFFError: LocalizedError, Sendable {
    case notFound
    case badResponse
    case invalidURL
    case decoding

    var errorDescription: String? {
        switch self {
        case .notFound: return "Product not found in OpenFoodFacts"
        case .badResponse: return "Unexpected response from OpenFoodFacts"
        case .invalidURL: return "Invalid OpenFoodFacts URL"
        case .decoding: return "Could not decode OpenFoodFacts response"
        }
    }
}

// MARK: - Service

final class OpenFoodFactsService: @unchecked Sendable {
    private let userAgent = "LeanLog/1.0 (https://github.com/LightYagamiTheDev/LeanLog)" // OFF recommends custom UA
    private let base = "https://world.openfoodfacts.net/api/v2" // v2 product endpoint
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Raw fetch kept internal; returns internal model (OK).
    func fetchByBarcode(_ barcode: String) async throws -> OFFProduct {
        guard let url = URL(string: "\(base)/product/\(barcode)") else {
            throw OFFError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")  // OFF guideline

        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw OFFError.badResponse
        }

        do {
            let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
            guard decoded.status == 1, let product = decoded.product else {
                throw OFFError.notFound
            }
            return product
        } catch {
            throw OFFError.decoding
        }
    }

    // High-level helper used by the scanner wrapper.
    func fetchResolvedFood(_ barcode: String) async throws -> OFFResolvedFood {
        let product = try await fetchByBarcode(barcode)
        return resolve(product: product, fallbackBarcode: barcode)
    }

    // MARK: - Resolution

    private func resolve(product: OFFProduct, fallbackBarcode: String) -> OFFResolvedFood {
        let name = displayName(product: product)
        let (servingSize, servingUnit) = parseServing(product.servingSize) ?? (100.0, "g")

        let kcal = product.nutriments?.energyKcalServing
            ?? scaled(valuePer100g: product.nutriments?.energyKcal100g ?? product.nutriments?.energyKcal, serving: servingSize)

        let protein = product.nutriments?.proteinsServing
            ?? scaled(valuePer100g: product.nutriments?.proteins100g ?? product.nutriments?.proteins, serving: servingSize)

        let carbs = product.nutriments?.carbohydratesServing
            ?? scaled(valuePer100g: product.nutriments?.carbohydrates100g ?? product.nutriments?.carbohydrates, serving: servingSize)

        let fat = product.nutriments?.fatServing
            ?? scaled(valuePer100g: product.nutriments?.fat100g ?? product.nutriments?.fat, serving: servingSize)

        return OFFResolvedFood(
            name: name,
            brand: product.brands,
            calories: Int((kcal ?? 0).rounded()),
            protein: (protein ?? 0),
            carbs: (carbs ?? 0),
            fat: (fat ?? 0),
            servingSize: servingSize,
            servingUnit: servingUnit,
            sourceBarcode: product.code ?? fallbackBarcode
        )
    }

    private func displayName(product: OFFProduct) -> String {
        let trimmed = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = (trimmed?.isEmpty == false) ? trimmed : nil
        if let brand = product.brands?.split(separator: ",").first.map({ String($0).trimmingCharacters(in: .whitespaces) }),
           let p {
            return "\(brand) \(p)"
        }
        return p ?? product.brands ?? "Unknown Product"
    }

    private func scaled(valuePer100g: Double?, serving: Double) -> Double? {
        guard let v = valuePer100g else { return nil }
        return v * (serving / 100.0)
    }

    private func parseServing(_ s: String?) -> (Double, String)? {
        guard let s = s?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }

        if let paren = s.range(of: #"\((.*?)\)"#, options: .regularExpression) {
            let inside = String(s[paren]).replacingOccurrences(of: ["(", ")"], with: "")
            if let t = firstNumberUnit(in: inside) { return t }
        }
        if let t = firstNumberUnit(in: s) { return t }
        if let n = firstNumberOnly(in: s) { return (n, "g") }
        return nil
    }

    private func firstNumberUnit(in s: String) -> (Double, String)? {
        let patterns = [
            #"(\d+(\.\d+)?)\s*(g|gram|grams)\b"#,
            #"(\d+(\.\d+)?)\s*(ml|milliliter|milliliters)\b"#
        ]
        for p in patterns {
            if let r = s.range(of: p, options: .regularExpression) {
                let token = String(s[r])
                let parts = token.split(whereSeparator: { $0.isWhitespace })
                if let num = Double(parts.first?.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression) ?? "") {
                    let unitToken = parts.last?.lowercased() ?? "g"
                    if unitToken.hasPrefix("ml") || unitToken.hasPrefix("milliliter") { return (num, "ml") }
                    return (num, "g")
                }
            }
        }
        return nil
    }

    private func firstNumberOnly(in s: String) -> Double? {
        if let r = s.range(of: #"(\d+(\.\d+)?)"#, options: .regularExpression) {
            return Double(s[r])
        }
        return nil
    }
}

// Convenience replace occurrences helper
private extension String {
    func replacingOccurrences(of targets: [String], with replacement: String = "") -> String {
        var result = self
        for t in targets { result = result.replacingOccurrences(of: t, with: replacement) }
        return result
    }
}
