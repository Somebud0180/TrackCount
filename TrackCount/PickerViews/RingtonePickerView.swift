//
//  RingtonePickerView.swift
//  TrackCount
//
//  Contains a list of ringtones from the asset `Ringtone.json` that can be selected
//

import SwiftUI
import AVFoundation

struct Ringtone: Identifiable, Decodable {
    let name: String
    let category: String
    var id: String { name }
}

struct RingtonePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("timerDefaultRingtone") var timerDefaultRingtone: String = DefaultSettings.timerDefaultRingtone
    
    // Use the shared AudioPlayerManager instance instead of creating a new one
    private let audioManager = AudioPlayerManager.shared
    @Binding var setVariable: String
    @State private var previewPlayer: AVAudioPlayer?
    var isFromSettings: Bool
    let ringtones: [Ringtone]
    
    init(setVariable: Binding<String>, fromSettings: Bool) {
        _setVariable = setVariable
        isFromSettings = fromSettings
        
        // Grab Ringtone Dataset
        if let dataAsset = NSDataAsset(name: "Ringtones") {
            do {
                ringtones = try JSONDecoder().decode([Ringtone].self, from: dataAsset.data)
            } catch {
                print("Failed to decode ringtones: \(error.localizedDescription)")
                ringtones = []
            }
        } else {
            ringtones = []
        }
    }
    
    var body: some View {
        VStack {
            /// Variable that stores black in light mode and white in dark mode.
            /// Used for items with non-white primary light mode colors (i.e. buttons).
            let primaryColor: Color = colorScheme == .light ? Color.black : Color.white
            
            NavigationStack {
                List {
                    if !isFromSettings {
                        Button(action: {
                            // Set variable with selected ringtone
                            setVariable = ""
                            audioManager.playAudio(audio: setVariable)
                        }) {
                            HStack {
                                Text("Default")
                                    .foregroundStyle(primaryColor)
                                Spacer()
                                if setVariable == "" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    let categories = Array(Set(ringtones.map { $0.category })).sorted()
                    
                    ForEach(categories, id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(ringtones.filter { $0.category == category }) { ringtone in
                                Button(action: {
                                    // Set variable with selected ringtone
                                    setVariable = ringtone.name
                                    audioManager.playAudio(audio: setVariable)
                                }) {
                                    HStack {
                                        Text(ringtone.name)
                                            .foregroundStyle(primaryColor)
                                        Spacer()
                                        if setVariable == ringtone.name {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle("Select a ringtone", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Dismiss") {
                            dismiss()
                        }
                    }
                }
                .onDisappear {
                    audioManager.stopAudio()
                }
            }
        }
        .onDisappear {
            audioManager.player?.stop()
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Failed to deactivate AVAudioSession: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var currentRingtone: String = "Kalimba"
    RingtonePickerView(setVariable: $currentRingtone, fromSettings: true)
}
