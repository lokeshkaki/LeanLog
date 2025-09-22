//
//  LeanLogApp.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/20/25.
//

import SwiftUI
import SwiftData

@main
struct LeanLogApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(try! SwiftData.ModelContainer(for: FoodEntry.self))
        }
    }
}
