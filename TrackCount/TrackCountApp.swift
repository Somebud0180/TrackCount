//
//  TrackCountApp.swift
//  TrackCount
//
//  Main application entry point
//

import SwiftUI
import SwiftData

@main
struct TrackCountApp: App {
    // Initialize managers when app starts - order matters for dependencies
    private let audioPlayerManager = AudioPlayerManager.shared // Initialize first
    private let notificationManager = NotificationManager.shared
    private let globalTimerManager = GlobalTimerManager.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: [DMStoredCard.self, DMCardGroup.self])
                .onAppear {
                    // Ensure all managers are properly initialized
                    _ = audioPlayerManager // Force initialization
                    _ = notificationManager
                    _ = globalTimerManager
                    
                    // Request notification permissions when app first appears
                    notificationManager.requestNotificationPermission()
                    
                    // Clear badge count when app becomes active
                    notificationManager.clearBadgeCount()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Clear badge when app becomes active
                    notificationManager.clearBadgeCount()
                }
        }
    }
}
