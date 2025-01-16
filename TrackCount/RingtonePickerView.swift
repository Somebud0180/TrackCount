//
//  RingtonePickerView.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 1/13/25.
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
    
    @Binding var setVariable: String
    @State private var player: AVAudioPlayer?
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
        /// Variable that stores black in light mode and white in dark mode.
        /// Used for items with non-white primary light mode colors (i.e. buttons).
        let primaryColor: Color = colorScheme == .light ? Color.black : Color.white
        
        NavigationStack {
            List {
                if !isFromSettings {
                    Button(action: {
                        // Set variable with selected ringtone
                        setVariable = ""
                        playAudio(audio: setVariable)
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
                                playAudio(audio: setVariable)
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
                player?.stop()
            }
        }
    }
    
    private func playAudio(audio: String) {
        do {
            // Handle default audio
            var ringtonePlaying = audio
            if audio.isEmpty {
                ringtonePlaying = timerDefaultRingtone
            }
            
            // Grab audio
            guard let dataAsset = NSDataAsset(name: ringtonePlaying) else {
                print("Data asset not found for: \(ringtonePlaying)")
                return
            }
            
            // Stop existing audio if any then try playing the audio
            player?.stop()
            player = try AVAudioPlayer(data: dataAsset.data)
            player?.play()
        } catch {
            print("Failed to play: \(error.localizedDescription)")
        }
    }
}

#Preview {
    @Previewable @State var currentRingtone: String = "Kalimba"
    RingtonePickerView(setVariable: $currentRingtone, fromSettings: true)
}
