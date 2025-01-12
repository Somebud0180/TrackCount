//
//  CtrlPanelApp.swift
//  CtrlPanel
//
//  Starts the app
//

import SwiftUI
import SwiftData

@main
struct TrackCountApp: App {
    @StateObject private var importManager = ImportManager()
    let container = try! ModelContainer(
        for: DMCardGroup.self, DMStoredCard.self,
        migrationPlan: ModelMigrationPlan.self
    )
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(container)
                .environmentObject(importManager)
        }
    }
}