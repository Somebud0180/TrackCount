//
//  UTTypeExtension.swift
//  TrackCount
//

import UniformTypeIdentifiers

extension UTType {
    static var trackCountGroup: UTType {
        // Grab the app bundle ID or fallback to default
        let bundleID = Bundle.main.bundleIdentifier ?? "com.ethanjohn.TrackCount"
        return UTType(exportedAs: bundleID, conformingTo: .data)
    }
}
