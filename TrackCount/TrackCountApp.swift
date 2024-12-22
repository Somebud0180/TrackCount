//
//  CtrlPanelApp.swift
//  CtrlPanel
//
//  Starts the app
//

import SwiftUI
import SwiftData

@main
struct CtrlPanelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: GridStore.self)
        }
    }
}
