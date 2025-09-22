//
//  OpenFoodFactsService.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

import Foundation

struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}
struct OFFProduct: Decodable {
    let product_name: String?
    let nutriments: OFFNutriments?
    let serving_size: String?
}
struct OFFNutriments: Decodable {
    let energy_kcal: Double?
    let energy_kcal_100g: Double?
    let proteins: Double?
    let proteins_100g: Double?
    let carbohydrates: Double?
    let carbohydrates_100g: Double?
    let fat: Double?
    let fat_100g: Double?
}

enum OFFError: Error { case notFound, badResponse }

final class OpenFoodFactsService {
    private let userAgent = "LeanLog/1.0 (support@example.com)" // OFF recommends a custom UA

    func fetchByBarcode(_ barcode: String) async throws -> OFFProduct {
        guard let url = URL(string: "https://world.openfoodfacts.net/api/v2/product/\(barcode)") else {
            throw OFFError.badResponse
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent") // required by OFF
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw OFFError.badResponse }
        let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else { throw OFFError.notFound }
        return product
    }
}
