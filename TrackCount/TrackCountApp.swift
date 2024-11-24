//
//  CtrlPanelApp.swift
//  CtrlPanel
//
//  Created by Ethan John Lagera on 11/20/24.
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
