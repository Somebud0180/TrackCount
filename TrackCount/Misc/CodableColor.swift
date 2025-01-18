//
//  CodableColor.swift
//  TrackCount
//
//  A codable version of color, used for model storage. via https://medium.com/geekculture/using-appstorage-with-swiftui-colors-and-some-nskeyedarchiver-magic-a38038383c5e
//

import SwiftUI

struct CodableColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    init(color: Color) {
        // Extract RGBA components from Color
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
    }
}
