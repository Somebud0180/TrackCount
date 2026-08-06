//
//  HomeView.swift
//  TrackCount
//
//  Contains the home screen
//

import SwiftUI
import SwiftData

struct DefaultSettings {
    static let timerDefaultRingtone = "Code"
    static let timerAlertEnabled = true
    static let gradientAnimated = true
    static let gradientInDarkHome = true
    static let gradientInDarkGroup = true
    static let trackGridSize = 1
    static let primaryThemeColor = RawColor(color: Color.blue.light)
}

// Helper to determine if Liquid Glass design is available
let usesLiquidGlass: Bool = {
    if #available(anyAppleOS 26.0, *) {
        return true
    } else {
        return false
    }
}()

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("gradientInDarkHome") var isGradientInDarkHome: Bool = DefaultSettings.gradientInDarkHome
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    var body: some View {
        NavigationStack {
            GroupListView()
                .environmentObject(ImportManager())
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
    }
}

extension Color {
    var light: Self {
        var environment = EnvironmentValues()
        environment.colorScheme = .light
        return Color(resolve(in: environment))
    }
    
    var dark: Self {
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        return Color(resolve(in: environment))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DMCardGroup.self)
}
