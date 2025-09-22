//
//  Secrets.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//

// Secrets.swift
import Foundation

enum Secrets {
    static var usdaApiKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["USDA_API_KEY"] as? String,
            !key.isEmpty
        else {
            assertionFailure("Missing USDA_API_KEY in Secrets.plist")
            return ""
        }
        return key
    }
}
