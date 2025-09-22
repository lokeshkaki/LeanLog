//
//  Item.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/20/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
