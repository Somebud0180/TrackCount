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
    var Row: Int
    var Column: Int
    var type: String
    var name: String
    var text: String
    var count: Int
    
    init(Row: Int, Column: Int, type: String, name: String, text: String, count: Int) {
        self.Row = Row
        self.Column = Column
        self.type = type
        self.name = name
        self.text = text
        self.count = count
    }
}
