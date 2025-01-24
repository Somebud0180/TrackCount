//
//  RawColor.swift
//  TrackCount
//
//  A RawRepresentable version of Color, used for AppStorage
//

import SwiftUI

struct RawColor: RawRepresentable, Codable {
    var rawValue: String
    
    // Color components
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    // Computed property to get SwiftUI Color
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    // Initialize from rawValue (String)
    init?(rawValue: String) {
        let components = rawValue.split(separator: ",")
        guard components.count == 4,
              let red = Double(components[0]),
              let green = Double(components[1]),
              let blue = Double(components[2]),
              let opacity = Double(components[3]) else {
            return nil
        }
        
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
        self.rawValue = "\(red),\(green),\(blue),\(opacity)"
    }
    
    // Initialize from Color
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
        self.rawValue = "\(red),\(green),\(blue),\(opacity)"
    }
}
