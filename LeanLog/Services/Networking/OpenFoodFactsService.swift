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

    // Carb details
    let sugars: Double?
    let fiber: Double?
    
    // Fat details
    let saturatedFat: Double?
    let transFat: Double?
    let monounsaturatedFat: Double?
    let polyunsaturatedFat: Double?
    
    // Cholesterol & sodium
    let cholesterol: Double?
    let sodium: Double?
    let salt: Double?
    
    // Major minerals
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let magnesium: Double?
    let phosphorus: Double?
    let zinc: Double?
    
    // Trace minerals
    let selenium: Double?
    let copper: Double?
    let manganese: Double?
    let chromium: Double?
    let molybdenum: Double?
    let iodine: Double?
    let chloride: Double?
    
    // Vitamins
    let vitaminA: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    let vitaminK: Double?
    
    // B Vitamins
    let thiamin: Double?
    let riboflavin: Double?
    let niacin: Double?
    let pantothenicAcid: Double?
    let vitaminB6: Double?
    let biotin: Double?
    let folate: Double?
    let vitaminB12: Double?
    
    // Other
    let choline: Double?
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
    
    let monounsaturatedFat: Double?
    let monounsaturatedFat100g: Double?
    let monounsaturatedFatServing: Double?
    
    let polyunsaturatedFat: Double?
    let polyunsaturatedFat100g: Double?
    let polyunsaturatedFatServing: Double?

    // Cholesterol
    let cholesterol: Double?
    let cholesterol100g: Double?
    let cholesterolServing: Double?

    // Major Minerals
    let potassium: Double?
    let potassium100g: Double?
    let potassiumServing: Double?

    let calcium: Double?
    let calcium100g: Double?
    let calciumServing: Double?

    let iron: Double?
    let iron100g: Double?
    let ironServing: Double?
    
    let magnesium: Double?
    let magnesium100g: Double?
    let magnesiumServing: Double?
    
    let phosphorus: Double?
    let phosphorus100g: Double?
    let phosphorusServing: Double?
    
    let zinc: Double?
    let zinc100g: Double?
    let zincServing: Double?

    // Trace Minerals
    let selenium: Double?
    let selenium100g: Double?
    let seleniumServing: Double?
    
    let copper: Double?
    let copper100g: Double?
    let copperServing: Double?
    
    let manganese: Double?
    let manganese100g: Double?
    let manganeseServing: Double?
    
    let chromium: Double?
    let chromium100g: Double?
    let chromiumServing: Double?
    
    let molybdenum: Double?
    let molybdenum100g: Double?
    let molybdenumServing: Double?
    
    let iodine: Double?
    let iodine100g: Double?
    let iodineServing: Double?
    
    let chloride: Double?
    let chloride100g: Double?
    let chlorideServing: Double?

    // Vitamins
    let vitaminA: Double?
    let vitaminA100g: Double?
    let vitaminAServing: Double?
    
    let vitaminC: Double?
    let vitaminC100g: Double?
    let vitaminCServing: Double?

    let vitaminD: Double?
    let vitaminD100g: Double?
    let vitaminDServing: Double?
    
    let vitaminE: Double?
    let vitaminE100g: Double?
    let vitaminEServing: Double?
    
    let vitaminK: Double?
    let vitaminK100g: Double?
    let vitaminKServing: Double?
    
    // B Vitamins
    let thiamin: Double?
    let thiamin100g: Double?
    let thiaminServing: Double?
    
    let riboflavin: Double?
    let riboflavin100g: Double?
    let riboflavinServing: Double?
    
    let niacin: Double?
    let niacin100g: Double?
    let niacinServing: Double?
    
    let pantothenicAcid: Double?
    let pantothenicAcid100g: Double?
    let pantothenicAcidServing: Double?
    
    let vitaminB6: Double?
    let vitaminB6_100g: Double?
    let vitaminB6Serving: Double?
    
    let biotin: Double?
    let biotin100g: Double?
    let biotinServing: Double?
    
    let folate: Double?
    let folate100g: Double?
    let folateServing: Double?
    
    let vitaminB12: Double?
    let vitaminB12_100g: Double?
    let vitaminB12Serving: Double?
    
    // Other
    let choline: Double?
    let choline100g: Double?
    let cholineServing: Double?

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
        
        case monounsaturatedFat = "monounsaturated-fat"
        case monounsaturatedFat100g = "monounsaturated-fat_100g"
        case monounsaturatedFatServing = "monounsaturated-fat_serving"
        
        case polyunsaturatedFat = "polyunsaturated-fat"
        case polyunsaturatedFat100g = "polyunsaturated-fat_100g"
        case polyunsaturatedFatServing = "polyunsaturated-fat_serving"

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
        
        case magnesium
        case magnesium100g      = "magnesium_100g"
        case magnesiumServing   = "magnesium_serving"
        
        case phosphorus
        case phosphorus100g     = "phosphorus_100g"
        case phosphorusServing  = "phosphorus_serving"
        
        case zinc
        case zinc100g           = "zinc_100g"
        case zincServing        = "zinc_serving"
        
        case selenium
        case selenium100g       = "selenium_100g"
        case seleniumServing    = "selenium_serving"
        
        case copper
        case copper100g         = "copper_100g"
        case copperServing      = "copper_serving"
        
        case manganese
        case manganese100g      = "manganese_100g"
        case manganeseServing   = "manganese_serving"
        
        case chromium
        case chromium100g       = "chromium_100g"
        case chromiumServing    = "chromium_serving"
        
        case molybdenum
        case molybdenum100g     = "molybdenum_100g"
        case molybdenumServing  = "molybdenum_serving"
        
        case iodine
        case iodine100g         = "iodine_100g"
        case iodineServing      = "iodine_serving"
        
        case chloride
        case chloride100g       = "chloride_100g"
        case chlorideServing    = "chloride_serving"

        case vitaminA           = "vitamin-a"
        case vitaminA100g       = "vitamin-a_100g"
        case vitaminAServing    = "vitamin-a_serving"
        
        case vitaminC           = "vitamin-c"
        case vitaminC100g       = "vitamin-c_100g"
        case vitaminCServing    = "vitamin-c_serving"

        case vitaminD           = "vitamin-d"
        case vitaminD100g       = "vitamin-d_100g"
        case vitaminDServing    = "vitamin-d_serving"
        
        case vitaminE           = "vitamin-e"
        case vitaminE100g       = "vitamin-e_100g"
        case vitaminEServing    = "vitamin-e_serving"
        
        case vitaminK           = "vitamin-k"
        case vitaminK100g       = "vitamin-k_100g"
        case vitaminKServing    = "vitamin-k_serving"
        
        case thiamin
        case thiamin100g        = "thiamin_100g"
        case thiaminServing     = "thiamin_serving"
        
        case riboflavin
        case riboflavin100g     = "riboflavin_100g"
        case riboflavinServing  = "riboflavin_serving"
        
        case niacin
        case niacin100g         = "niacin_100g"
        case niacinServing      = "niacin_serving"
        
        case pantothenicAcid    = "pantothenic-acid"
        case pantothenicAcid100g = "pantothenic-acid_100g"
        case pantothenicAcidServing = "pantothenic-acid_serving"
        
        case vitaminB6          = "vitamin-b6"
        case vitaminB6_100g     = "vitamin-b6_100g"
        case vitaminB6Serving   = "vitamin-b6_serving"
        
        case biotin
        case biotin100g         = "biotin_100g"
        case biotinServing      = "biotin_serving"
        
        case folate
        case folate100g         = "folate_100g"
        case folateServing      = "folate_serving"
        
        case vitaminB12         = "vitamin-b12"
        case vitaminB12_100g    = "vitamin-b12_100g"
        case vitaminB12Serving  = "vitamin-b12_serving"
        
        case choline
        case choline100g        = "choline_100g"
        case cholineServing     = "choline_serving"
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
    private let userAgent = "LeanLog/1.0 (https://github.com/LightYagamiTheDev/LeanLog)"
    private let base = "https://world.openfoodfacts.net/api/v2"
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
            // Carb details
            sugars: micros.sugars,
            fiber: micros.fiber,
            // Fat details
            saturatedFat: micros.saturatedFat,
            transFat: micros.transFat,
            monounsaturatedFat: micros.monounsaturatedFat,
            polyunsaturatedFat: micros.polyunsaturatedFat,
            // Cholesterol & sodium
            cholesterol: micros.cholesterol,
            sodium: derived.sodium,
            salt: derived.salt,
            // Major minerals
            potassium: micros.potassium,
            calcium: micros.calcium,
            iron: micros.iron,
            magnesium: micros.magnesium,
            phosphorus: micros.phosphorus,
            zinc: micros.zinc,
            // Trace minerals
            selenium: micros.selenium,
            copper: micros.copper,
            manganese: micros.manganese,
            chromium: micros.chromium,
            molybdenum: micros.molybdenum,
            iodine: micros.iodine,
            chloride: micros.chloride,
            // Vitamins
            vitaminA: micros.vitaminA,
            vitaminC: micros.vitaminC,
            vitaminD: micros.vitaminD,
            vitaminE: micros.vitaminE,
            vitaminK: micros.vitaminK,
            // B Vitamins
            thiamin: micros.thiamin,
            riboflavin: micros.riboflavin,
            niacin: micros.niacin,
            pantothenicAcid: micros.pantothenicAcid,
            vitaminB6: micros.vitaminB6,
            biotin: micros.biotin,
            folate: micros.folate,
            vitaminB12: micros.vitaminB12,
            // Other
            choline: micros.choline
        )
    }

    private func displayName(product: OFFProduct) -> String {
        let n = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return n.isEmpty ? "Unknown Product" : n
    }

    private func parseServing(_ str: String?) -> (size: Double, unit: String)? {
        guard let s = str?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        let pattern = #"^([\d.,]+)\s*([a-zA-Z]+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else {
            return nil
        }
        guard let numRange = Range(match.range(at: 1), in: s),
              let unitRange = Range(match.range(at: 2), in: s) else {
            return nil
        }
        let numStr = String(s[numRange]).replacingOccurrences(of: ",", with: ".")
        guard let size = Double(numStr) else { return nil }
        let unit = String(s[unitRange])
        return (size, unit)
    }

    private func scaled(valuePer100g: Double?, serving: Double) -> Double? {
        guard let v = valuePer100g else { return nil }
        return v * (serving / 100.0)
    }

    private func resolvedMicros(_ n: OFFNutriments?, serving: Double) -> (
        sugars: Double?,
        fiber: Double?,
        saturatedFat: Double?,
        transFat: Double?,
        monounsaturatedFat: Double?,
        polyunsaturatedFat: Double?,
        cholesterol: Double?,
        sodium: Double?,
        salt: Double?,
        potassium: Double?,
        calcium: Double?,
        iron: Double?,
        magnesium: Double?,
        phosphorus: Double?,
        zinc: Double?,
        selenium: Double?,
        copper: Double?,
        manganese: Double?,
        chromium: Double?,
        molybdenum: Double?,
        iodine: Double?,
        chloride: Double?,
        vitaminA: Double?,
        vitaminC: Double?,
        vitaminD: Double?,
        vitaminE: Double?,
        vitaminK: Double?,
        thiamin: Double?,
        riboflavin: Double?,
        niacin: Double?,
        pantothenicAcid: Double?,
        vitaminB6: Double?,
        biotin: Double?,
        folate: Double?,
        vitaminB12: Double?,
        choline: Double?
    ) {
        func pick(_ servingVal: Double?, _ per100g: Double?) -> Double? {
            servingVal ?? scaled(valuePer100g: per100g, serving: serving)
        }
        
        return (
            sugars: pick(n?.sugarsServing, n?.sugars100g ?? n?.sugars),
            fiber: pick(n?.fiberServing, n?.fiber100g ?? n?.fiber),
            saturatedFat: pick(n?.saturatedFatServing, n?.saturatedFat100g ?? n?.saturatedFat),
            transFat: pick(n?.transFatServing, n?.transFat100g ?? n?.transFat),
            monounsaturatedFat: pick(n?.monounsaturatedFatServing, n?.monounsaturatedFat100g ?? n?.monounsaturatedFat),
            polyunsaturatedFat: pick(n?.polyunsaturatedFatServing, n?.polyunsaturatedFat100g ?? n?.polyunsaturatedFat),
            cholesterol: pick(n?.cholesterolServing, n?.cholesterol100g ?? n?.cholesterol),
            sodium: pick(n?.sodiumServing, n?.sodium100g ?? n?.sodium),
            salt: pick(n?.saltServing, n?.salt100g ?? n?.salt),
            potassium: pick(n?.potassiumServing, n?.potassium100g ?? n?.potassium),
            calcium: pick(n?.calciumServing, n?.calcium100g ?? n?.calcium),
            iron: pick(n?.ironServing, n?.iron100g ?? n?.iron),
            magnesium: pick(n?.magnesiumServing, n?.magnesium100g ?? n?.magnesium),
            phosphorus: pick(n?.phosphorusServing, n?.phosphorus100g ?? n?.phosphorus),
            zinc: pick(n?.zincServing, n?.zinc100g ?? n?.zinc),
            selenium: pick(n?.seleniumServing, n?.selenium100g ?? n?.selenium),
            copper: pick(n?.copperServing, n?.copper100g ?? n?.copper),
            manganese: pick(n?.manganeseServing, n?.manganese100g ?? n?.manganese),
            chromium: pick(n?.chromiumServing, n?.chromium100g ?? n?.chromium),
            molybdenum: pick(n?.molybdenumServing, n?.molybdenum100g ?? n?.molybdenum),
            iodine: pick(n?.iodineServing, n?.iodine100g ?? n?.iodine),
            chloride: pick(n?.chlorideServing, n?.chloride100g ?? n?.chloride),
            vitaminA: pick(n?.vitaminAServing, n?.vitaminA100g ?? n?.vitaminA),
            vitaminC: pick(n?.vitaminCServing, n?.vitaminC100g ?? n?.vitaminC),
            vitaminD: pick(n?.vitaminDServing, n?.vitaminD100g ?? n?.vitaminD),
            vitaminE: pick(n?.vitaminEServing, n?.vitaminE100g ?? n?.vitaminE),
            vitaminK: pick(n?.vitaminKServing, n?.vitaminK100g ?? n?.vitaminK),
            thiamin: pick(n?.thiaminServing, n?.thiamin100g ?? n?.thiamin),
            riboflavin: pick(n?.riboflavinServing, n?.riboflavin100g ?? n?.riboflavin),
            niacin: pick(n?.niacinServing, n?.niacin100g ?? n?.niacin),
            pantothenicAcid: pick(n?.pantothenicAcidServing, n?.pantothenicAcid100g ?? n?.pantothenicAcid),
            vitaminB6: pick(n?.vitaminB6Serving, n?.vitaminB6_100g ?? n?.vitaminB6),
            biotin: pick(n?.biotinServing, n?.biotin100g ?? n?.biotin),
            folate: pick(n?.folateServing, n?.folate100g ?? n?.folate),
            vitaminB12: pick(n?.vitaminB12Serving, n?.vitaminB12_100g ?? n?.vitaminB12),
            choline: pick(n?.cholineServing, n?.choline100g ?? n?.choline)
        )
    }

    private func deriveSaltSodiumIfMissing(sodium: Double?, salt: Double?) -> (sodium: Double?, salt: Double?) {
        if let s = sodium, salt == nil {
            return (s, s * 2.5)
        }
        if let sa = salt, sodium == nil {
            return (sa * 0.393, sa)
        }
        return (sodium, salt)
    }
}
