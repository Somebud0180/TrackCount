//
//  ContentView.swift
//  TrackCount
//
//  Contains the home screen
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var teamOne = 0
    @State private var teamTwo = 0
    @State private var cardNames: [String] = []
    @State private var counterStates: [Int] = []
    @State private var buttonStates: [Int: Bool] = [:]
    
    @Query private var gridStore: [GridStore]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("TrackCount")
                    .font(.system(size: 64))
                
                Grid(alignment: .center) {
                    NavigationLink(destination: TrackScreen(teamOne: $teamOne, teamTwo: $teamTwo, cardNames: $cardNames, counterStates: $counterStates, buttonStates: $buttonStates)) {
                        Text("Track It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: EditScreen(teamOne: $teamOne, teamTwo: $teamTwo, cardNames: $cardNames, counterStates: $counterStates, buttonStates: $buttonStates)) {
                        Text("Edit It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
