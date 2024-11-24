//
//  EditView.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 11/22/24.
//

import SwiftUI
import SwiftData

struct editScreen: View {
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var cardNames: [String]
    @Binding var counterStates: [Int]
    @Binding var buttonStates: [Int: Bool]
    
    @Query private var gridStore: [GridStore]
    @Environment(\.modelContext) private var context
    
    @State private var newCardRow: String = ""
    @State private var newCardColumn: String = ""
    @State private var newCardType = types.counter
    @State private var newCardText: String = ""
    @State private var newCardCount: Int = 1
    @State private var newCardState: Bool = true
    
    enum types: String, Codable, CaseIterable {
        case counter
        case toggle
    }
    
    var body: some View {
        VStack {
            TextField("Enter counter names", text: $newCardText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if !newCardText.isEmpty {
                    cardNames.append(newCardText) // Append to the cardNames array
                    newCardText = "" // Clear the input field
                }
            }) {
                Text("Add Name")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            List {
                Picker(selection: $newCardType) {
                    Text("Counter").tag(types.counter)
                    Text("Toggle").tag(types.toggle)
                } label: {
                    Text("Type")
                    Text("Choose a card type")
                }
                
                TextField("Set card text", text: $newCardText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if (newCardType == types.toggle) {
                    Stepper("Buttons: \(newCardCount)", value: $newCardCount, in: 1...12)
                }
            
                
                Button(action: {
                    if !newCardText.isEmpty {
                        cardNames.append(newCardText) // Append to the cardNames array
                        newCardText = "" // Clear the input field
                    }
                }) {
                    Text("Add")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Display current card names
            List(cardNames, id: \.self) { name in
                Text(name)
            }
        }
    }
}

#Preview {
    ContentView()
}
