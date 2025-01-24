//
//  TrackCountApp.swift
//  TrackCount
//
//  Starts the app
//

import SwiftUI
import SwiftData

@main
struct TrackCountApp: App {
    @StateObject private var importManager = ImportManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: DMCardGroup.self)
                .environmentObject(importManager)
        }
    }
}
