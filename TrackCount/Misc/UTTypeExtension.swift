//
//  UTTypeExtension.swift
//  TrackCount
//

import UniformTypeIdentifiers

extension UTType {
    static var trackCountGroup: UTType {
        // Grabs your app’s real bundle identifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.ethanjohn.TrackCount"
        // Constructs a UTType from that bundle ID
        return UTType(exportedAs: bundleID, conformingTo: .data)
    }
}
