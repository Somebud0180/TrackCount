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
        }
    }
}
