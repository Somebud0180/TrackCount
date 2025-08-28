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
    
    init() {
        // Request notification permissions on app launch
        NotificationManager.shared.requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(importManager)
                .onAppear {
                    // Initialize global timer manager
                    _ = GlobalTimerManager.shared
                }
        }
        .modelContainer(for: DMCardGroup.self)
    }
}
