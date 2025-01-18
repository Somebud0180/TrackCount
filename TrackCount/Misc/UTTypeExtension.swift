//
//  UTTypeExtension.swift
//  TrackCount
//

import UniformTypeIdentifiers

extension UTType {
    static var trackCountGroup: UTType {
        UTType(exportedAs: "com.ethanjohn.TrackCount", conformingTo: .data)
    }
}
