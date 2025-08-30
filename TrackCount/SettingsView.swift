//
//  SettingsView.swift
//  TrackCount
//
//  Contains the preferences and info about the app
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("timerAlertEnabled") var isTimerAlertEnabled: Bool = DefaultSettings.timerAlertEnabled
    @AppStorage("timerDefaultRingtone") var timerDefaultRingtone: String = DefaultSettings.timerDefaultRingtone
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("gradientInDarkHome") var isGradientInDarkHome: Bool = DefaultSettings.gradientInDarkHome
    @AppStorage("gradientInDarkGroup") var isGradientInDarkGroup: Bool = DefaultSettings.gradientInDarkGroup
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    @State private var isPresentingRingtonePickerView: Bool = false
    @State private var primaryThemeSwiftColor: Color = .blue
    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .center, spacing: 10) {
                    Image(colorScheme == .light ? "TrackCountIconLight" : "TrackCountIconDark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 50, maxWidth: 100, alignment: .center)
                    Text("TrackCount")
                        .font(.system(.title, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.primary)
                    Text("Manage preferences and view details about the app")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                
                Section(header: Text("Theme")) {
                    Toggle("Animate Gradient", isOn: $isGradientAnimated)
                    ColorPicker("Gradient Color", selection: $primaryThemeSwiftColor)
                        .onChange(of: primaryThemeSwiftColor) {
                            saveColor(primaryThemeSwiftColor, to: &primaryThemeColor)
                        }
                    Button("Reset Gradient Color") {
                        primaryThemeColor = DefaultSettings.primaryThemeColor
                        primaryThemeSwiftColor = primaryThemeColor.color
                    }
                }
                
                Section(header: Text("Theme (Dark)")) {
                    Toggle("Use Gradient in Home", isOn: $isGradientInDarkHome)
                    Toggle("Use Gradient in Group Cards", isOn: $isGradientInDarkGroup)
                }
                
                Section(header: Text("Timers")) {
                    Toggle("Play Ringtone When Timer Ends", isOn: $isTimerAlertEnabled)
                    HStack {
                        Button("Default Ringtone") {
                            isPresentingRingtonePickerView = true
                        }
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                        
                        Spacer()
                        
                        Text("\(timerDefaultRingtone)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(footer:
                    VStack {
                        Link("Made with ❤️ Hack Club", destination: URL(string: "https://hackclub.com/")!)
                        Link("Source Code on GitHub", destination: URL(string: "https://github.com/Somebud0180/TrackCount")!)
                        HStack {
                            Text("Version \(version) (\(build))")
                        }
                        .accessibilityLabel("Version")
                        .accessibilityValue(Text("\(version) (\(build))"))
                }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
                ) {
                }
                .padding(.bottom)
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .sheet(isPresented: $isPresentingRingtonePickerView) {
                RingtonePickerView(setVariable: $timerDefaultRingtone, fromSettings: true)
            }
        }
        .onAppear { primaryThemeSwiftColor = primaryThemeColor.color }
    }
    
    private func saveColor(_ swiftColor: Color, to appStorageColor: inout RawColor) {
        let newColor = RawColor(color: swiftColor)
        appStorageColor = newColor
    }
}

#Preview {
    SettingsView()
}
