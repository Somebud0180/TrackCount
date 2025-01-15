//
//  SettingsView.swift
//  TrackCount
//
//  Contains the preferences and info about the app
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("timerAlertEnabled") var isTimerAlertEnabled: Bool = DefaultSettings.timerAlertEnabled
    @AppStorage("timerDeafultRingtone") var timerDeafultRingtone: String = DefaultSettings.timerDefaultRingtone
    
    @State private var isPresentingRingtonePickerView: Bool = false
    let version : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    let build : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
    
    var body: some View {
        let isLight = colorScheme == .light
        NavigationStack {
            Form {
                VStack(alignment: .center, spacing: 10) {
                    Image(isLight ? "TrackCountIconLight" : "TrackCountIconDark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(minWidth: 50, maxWidth: 100, alignment: .center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary, lineWidth: 0.5)
                        )
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
                
                Section(header: Text("Timers")) {
                    Toggle("Timer Alerts", isOn: $isTimerAlertEnabled)
                    HStack {
                        Button("Default Timer Ringtone") {
                            isPresentingRingtonePickerView.toggle()
                        }
                        .foregroundStyle(isLight ? .black : .white)
                        
                        Spacer()
                        
                        Text("\(timerDeafultRingtone)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(version ?? "Unknown") (\(build ?? "1"))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isPresentingRingtonePickerView) {
                RingtonePickerView(setVariable: $timerDeafultRingtone, fromSettings: true)
            }
        }
    }
}

#Preview {
    SettingsView()
}
