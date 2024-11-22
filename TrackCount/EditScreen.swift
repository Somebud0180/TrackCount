//
//  EditView.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 11/22/24.
//

import SwiftUI

struct editScreen: View {
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var cardNames: [String]
    @Binding var counterStates: [Int]
    @Binding var buttonStates: [Int: Bool]
    @Binding var gridStore: [GridStore]
    
    @State private var newCardName: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter counter names", text: $newCardName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if !newCardName.isEmpty {
                    cardNames.append(newCardName) // Append to the cardNames array
                    newCardName = "" // Clear the input field
                }
            }) {
                Text("Add Name")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
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
