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
    static let primaryThemeColor = RawColor(color: Color.blue.light)
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("gradientInDarkHome") var isGradientInDarkHome: Bool = DefaultSettings.gradientInDarkHome
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    var body: some View {
        TabView {
            // Home Tab
            GroupListView()
                .environmentObject(ImportManager())
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
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
