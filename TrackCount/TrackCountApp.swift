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
    // Initialize the notification manager when app starts
    private let notificationManager = NotificationManager.shared
    private let globalTimerManager = GlobalTimerManager.shared
    private let audioPlayerManager = AudioPlayerManager.shared // Add centralized audio manager
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: [DMStoredCard.self, DMCardGroup.self])
                .onAppear {
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
