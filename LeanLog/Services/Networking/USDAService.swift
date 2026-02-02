//
//  USDAService.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import Foundation

struct FDCSearchResponse: Decodable { let foods: [FDCSearchFood] }

struct FDCSearchFood: Decodable, Identifiable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let servingSize: Double?
    let servingUnit: String?
    var id: Int { fdcId }
}

struct FDCFoodDetail: Decodable {
    let description: String?
    let brandOwner: String?
    let foodNutrients: [FDCNutrient]?
    let foodPortions: [FDCFoodPortion]?
    
    struct FDCFoodPortion: Decodable {
        let gramWeight: Double?
        let amount: Double?
        let modifier: String?
        let measureUnit: FDCMeasureUnit?
    }
    
    struct FDCMeasureUnit: Decodable {
        let name: String?
        let abbreviation: String?
    }
    
    var actualServingSize: Double? {
        foodPortions?.first?.gramWeight
    }
    
    var actualServingUnit: String? {
        foodPortions?.first?.modifier ?? foodPortions?.first?.measureUnit?.name
    }
}

struct FDCNutrient: Decodable {
    let nutrient: FDCNutrientInfo?
    let amount: Double?
    
    struct FDCNutrientInfo: Decodable {
        let name: String
        let unitName: String?
    }
    
    // Computed property to match the old interface
    var nutrientName: String {
        nutrient?.name ?? ""
    }
    
    var value: Double? {
        amount
    }
    
    var unitName: String? {
        nutrient?.unitName
    }
}

enum USDAServiceError: LocalizedError {
    case badURL
    case noData
    case decodeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodeFailed(let error):
            return "Decode failed: \(error.localizedDescription)"
        }
    }
}

final class USDAService {
    private let apiKey: String
    private let base = "https://api.nal.usda.gov/fdc/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [FDCSearchFood] {
        guard var comps = URLComponents(string: "\(base)/foods/search") else {
            throw USDAServiceError.badURL
        }

        comps.queryItems = [
            .init(name: "query", value: query),
            .init(name: "pageSize", value: String(pageSize))
        ]

        guard let url = comps.url else {
            throw USDAServiceError.badURL
        }

        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1

        guard code == 200 else {
            if let body = String( data: data, encoding: .utf8) {
                print("USDA search error response: \(body)")
            }
            throw USDAServiceError.noData
        }

        do {
            let result = try JSONDecoder().decode(FDCSearchResponse.self, from: data)
            return result.foods
        } catch {
            throw USDAServiceError.decodeFailed(error)
        }
    }

    func fetchFoodDetail(fdcId: Int) async throws -> FDCFoodDetail {
        guard let url = URL(string: "\(base)/food/\(fdcId)") else {
            throw USDAServiceError.badURL
        }

        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1

        guard code == 200 else {
            if let body = String( data: data, encoding: .utf8) {
                print("USDA detail error response: \(body)")
            }
            throw USDAServiceError.noData
        }

        do {
            let detail = try JSONDecoder().decode(FDCFoodDetail.self, from: data)
            return detail
        } catch {
            print("USDA RESPONSE:", String( data: data, encoding: .utf8) ?? "---nil---")
            throw USDAServiceError.decodeFailed(error)
        }
    }
}

// Helper struct for storing extracted macros
struct Macros {
    let kcal: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

extension FDCFoodDetail {
    func extractMacros() -> Macros {
        guard let foodNutrients = foodNutrients else {
            return Macros(kcal: 0, protein: 0, carbs: 0, fat: 0)
        }
        
        func findValue(byName name: String, preferExact: String? = nil) -> Double {
            // First try to find exact match if specified
            if let exact = preferExact {
                if let exactMatch = foodNutrients.first(where: { $0.nutrientName.lowercased() == exact.lowercased() }) {
                    return exactMatch.value ?? 0
                }
            }
            
            // Fall back to contains search
            return foodNutrients.first(where: { $0.nutrientName.lowercased().contains(name) })?.value ?? 0
        }
        
        return Macros(
            kcal: Int(findValue(byName: "energy").rounded()),
            protein: findValue(byName: "protein"),
            carbs: findValue(byName: "carbohydrate", preferExact: "Carbohydrate, by difference"),
            fat: findValue(byName: "total lipid")
        )
    }
}
