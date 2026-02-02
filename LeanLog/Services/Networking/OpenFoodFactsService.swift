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

    // Micronutrients (per serving, grams where applicable)
    let sugars: Double?
    let fiber: Double?
    let sodium: Double?
    let salt: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let cholesterol: Double?
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let vitaminD: Double?
    let vitaminC: Double?
    let vitaminA: Double?
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
    // Energy (kcal)
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

    // Sugars
    let sugars: Double?
    let sugars100g: Double?
    let sugarsServing: Double?

    // Fiber
    let fiber: Double?
    let fiber100g: Double?
    let fiberServing: Double?

    // Sodium / Salt
    let sodium: Double?
    let sodium100g: Double?
    let sodiumServing: Double?

    let salt: Double?
    let salt100g: Double?
    let saltServing: Double?

    // Fat quality
    let saturatedFat: Double?
    let saturatedFat100g: Double?
    let saturatedFatServing: Double?

    let transFat: Double?
    let transFat100g: Double?
    let transFatServing: Double?

    // Cholesterol
    let cholesterol: Double?
    let cholesterol100g: Double?
    let cholesterolServing: Double?

    // Minerals
    let potassium: Double?
    let potassium100g: Double?
    let potassiumServing: Double?

    let calcium: Double?
    let calcium100g: Double?
    let calciumServing: Double?

    let iron: Double?
    let iron100g: Double?
    let ironServing: Double?

    // Vitamins
    let vitaminD: Double?
    let vitaminD100g: Double?
    let vitaminDServing: Double?

    let vitaminC: Double?
    let vitaminC100g: Double?
    let vitaminCServing: Double?

    let vitaminA: Double?
    let vitaminA100g: Double?
    let vitaminAServing: Double?

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

        case sugars
        case sugars100g         = "sugars_100g"
        case sugarsServing      = "sugars_serving"

        case fiber
        case fiber100g          = "fiber_100g"
        case fiberServing       = "fiber_serving"

        case sodium
        case sodium100g         = "sodium_100g"
        case sodiumServing      = "sodium_serving"

        case salt
        case salt100g           = "salt_100g"
        case saltServing        = "salt_serving"

        case saturatedFat       = "saturated-fat"
        case saturatedFat100g   = "saturated-fat_100g"
        case saturatedFatServing = "saturated-fat_serving"

        case transFat           = "trans-fat"
        case transFat100g       = "trans-fat_100g"
        case transFatServing    = "trans-fat_serving"

        case cholesterol
        case cholesterol100g    = "cholesterol_100g"
        case cholesterolServing = "cholesterol_serving"

        case potassium
        case potassium100g      = "potassium_100g"
        case potassiumServing   = "potassium_serving"

        case calcium
        case calcium100g        = "calcium_100g"
        case calciumServing     = "calcium_serving"

        case iron
        case iron100g           = "iron_100g"
        case ironServing        = "iron_serving"

        case vitaminD           = "vitamin-d"
        case vitaminD100g       = "vitamin-d_100g"
        case vitaminDServing    = "vitamin-d_serving"

        case vitaminC           = "vitamin-c"
        case vitaminC100g       = "vitamin-c_100g"
        case vitaminCServing    = "vitamin-c_serving"

        case vitaminA           = "vitamin-a"
        case vitaminA100g       = "vitamin-a_100g"
        case vitaminAServing    = "vitamin-a_serving"
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

    // Raw fetch kept internal; returns internal model.
    func fetchByBarcode(_ barcode: String) async throws -> OFFProduct {
        guard let url = URL(string: "\(base)/product/\(barcode)") else {
            throw OFFError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

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

        // Micronutrients: prefer _serving, fallback to scaled _100g
        let micros = resolvedMicros(product.nutriments, serving: servingSize)

        // Derive sodium/salt if one is missing: salt ≈ sodium × 2.5; sodium ≈ salt × 0.393 (by mass ratio) — both in grams
        let derived = deriveSaltSodiumIfMissing(sodium: micros.sodium, salt: micros.salt)

        return OFFResolvedFood(
            name: name,
            brand: product.brands,
            calories: Int((kcal ?? 0).rounded()),
            protein: (protein ?? 0),
            carbs: (carbs ?? 0),
            fat: (fat ?? 0),
            servingSize: servingSize,
            servingUnit: servingUnit,
            sourceBarcode: product.code ?? fallbackBarcode,
            sugars: micros.sugars,
            fiber: micros.fiber,
            sodium: derived.sodium,
            salt: derived.salt,
            saturatedFat: micros.saturatedFat,
            transFat: micros.transFat,
            cholesterol: micros.cholesterol,
            potassium: micros.potassium,
            calcium: micros.calcium,
            iron: micros.iron,
            vitaminD: micros.vitaminD,
            vitaminC: micros.vitaminC,
            vitaminA: micros.vitaminA
        )
    }

    private func resolvedMicros(_ n: OFFNutriments?, serving: Double) -> (
        sugars: Double?, fiber: Double?, sodium: Double?, salt: Double?,
        saturatedFat: Double?, transFat: Double?, cholesterol: Double?,
        potassium: Double?, calcium: Double?, iron: Double?,
        vitaminD: Double?, vitaminC: Double?, vitaminA: Double?
    ) {
        guard let n else {
            return (nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)
        }
        func pref(_ servingVal: Double?, _ per100: Double?, _ raw: Double?) -> Double? {
            servingVal ?? scaled(valuePer100g: per100 ?? raw, serving: serving)
        }
        let sugars = pref(n.sugarsServing, n.sugars100g, n.sugars)
        let fiber  = pref(n.fiberServing, n.fiber100g, n.fiber)
        let sodium = pref(n.sodiumServing, n.sodium100g, n.sodium)
        let salt   = pref(n.saltServing, n.salt100g, n.salt)
        let sat    = pref(n.saturatedFatServing, n.saturatedFat100g, n.saturatedFat)
        let trans  = pref(n.transFatServing, n.transFat100g, n.transFat)
        let chol   = pref(n.cholesterolServing, n.cholesterol100g, n.cholesterol)
        let k      = pref(n.potassiumServing, n.potassium100g, n.potassium)
        let ca     = pref(n.calciumServing, n.calcium100g, n.calcium)
        let fe     = pref(n.ironServing, n.iron100g, n.iron)
        let vd     = pref(n.vitaminDServing, n.vitaminD100g, n.vitaminD)
        let vc     = pref(n.vitaminCServing, n.vitaminC100g, n.vitaminC)
        let va     = pref(n.vitaminAServing, n.vitaminA100g, n.vitaminA)
        return (sugars, fiber, sodium, salt, sat, trans, chol, k, ca, fe, vd, vc, va)
    }

    private func deriveSaltSodiumIfMissing(sodium: Double?, salt: Double?) -> (sodium: Double?, salt: Double?) {
        // OFF values are normalized in grams for per-100g and per-serving
        if let sodium, salt == nil {
            // salt (g) ≈ sodium (g) * 2.5
            return (sodium, sodium * 2.5)
        }
        if let salt, sodium == nil {
            // sodium (g) ≈ salt (g) * 0.393
            return (salt * 0.393, salt)
        }
        return (sodium, salt)
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
