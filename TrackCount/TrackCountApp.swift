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
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: DMCardGroup.self)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.pathExtension == "trackcount" else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let container = try ModelContainer(for: DMCardGroup.self)
            let context = ModelContext(container)
            
            let importedGroup = try DMCardGroup.decodeFromShared(data, context: context)
            context.insert(importedGroup)
            try context.save()
            
        } catch {
            print("Failed to import group: \(error)")
        }
    }
}
