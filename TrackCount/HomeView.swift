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
    
    @Query private var savedGroups: [DMCardGroup]
    @State private var animateGradient: Bool = false
    @State private var isPresentingSettingsView: Bool = false
    
    /// Dynamically computes gradient colors based on colorScheme.
    private var gradientColors: [Color] {
        colorScheme == .light ? [.white, primaryThemeColor.color] : [.black, isGradientInDarkHome ? primaryThemeColor.color : .gray]
    }
    
    var body: some View {
        let backgroundGradient = LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        
        NavigationStack {
            GeometryReader { proxy in
                ZStack{
                    Rectangle()
                        .foregroundStyle(backgroundGradient)
                        .edgesIgnoringSafeArea(.all)
                        .hueRotation(.degrees(animateGradient ? 30 : 0))
                        .task {
                            if isGradientAnimated {
                                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                                    animateGradient.toggle()
                                }
                            }
                        }

                    if colorScheme == .light {
                        // A thin material to soften the gradient background
                        Rectangle()
                            .foregroundStyle(.secondary.opacity(0.2))
                            .ignoresSafeArea()
                    }
                    
                    VStack {
                        // Title
                        Text("TrackCount")
                            .font(.system(.largeTitle, design: .default, weight: .semibold))
                            .dynamicTypeSize(DynamicTypeSize.accessibility5)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(Color.white.opacity(0.8))
                            .shadow(radius: 1)
                        
                        // Buttons
                        Grid(alignment: .center) {
                            NavigationLink(destination:
                                GroupListView()
                                    .environmentObject(ImportManager())
                            ){
                                Text("Track It")
                                    .font(.largeTitle)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility1)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, minHeight: 25)
                                    .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
                                    .background(.ultraThinMaterial)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .shadow(radius: 1)
                            
                            NavigationLink(destination: GuideListView()){
                                Text("Guides")
                                    .font(.largeTitle)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility1)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, minHeight: 25)
                                    .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
                                    .background(.ultraThinMaterial)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .shadow(radius: 1)
                            
                            Button(action: {
                                isPresentingSettingsView.toggle()
                            }) {
                                Text("Settings")
                                    .font(.largeTitle)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility1)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, minHeight: 25)
                                    .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
                                    .background(.ultraThinMaterial)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .shadow(radius: 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $isPresentingSettingsView) {
                    SettingsView()
                }
            }
        }
        .accentColor(colorScheme == .light ? .black : .primary)
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
