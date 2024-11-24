//
//  GridStore.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 11/22/24.
//

import Foundation
import SwiftData

@Model
class GridStore {
    enum types: String, Codable, CaseIterable {
        case counter
        case toggle
    }
    
    var row: Int // Position on the X-axis
    var column: Int // Position on the Y-axis
    var type: types // Either a counter or toggle
    var text: String // The title (counter) or text in button (toggle)
    var count: Int // The amount counted (counter)
    var state: Bool // The boolean of the button (toggle)
    
    init(row: Int, column: Int, type: types, text: String, count: Int, state: Bool) {
        self.row = row
        self.column = column
        self.type = type
        self.text = text
        self.count = count
        self.state = state
    }
}
