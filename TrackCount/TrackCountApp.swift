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
            ContentView()
                .modelContainer(for: CardStore.self)
        }
    }
}
