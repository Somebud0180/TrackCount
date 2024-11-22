//
//  ContentView.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 11/20/24.
//

import SwiftUI

struct ContentView: View {
    @State private var teamOne = 0
    @State private var teamTwo = 0
    @State private var buttonGroup = 12
    @State private var buttonStates: [Bool] = Array(repeating: false, count: 48)
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("TrackCount")
                    .font(.system(size: 64))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                NavigationLink(destination: trackScreen(teamOne: $teamOne, teamTwo: $teamTwo, buttonGroup: $buttonGroup, buttonStates: $buttonStates)) {
                    Text("Track It")
                        .font(.system(size: 32))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding()
            }
        }
    }
}

struct trackScreen: View {
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var buttonGroup: Int
    @Binding var buttonStates: [Bool]
    
    func buttonTextIcon(count: Int, text: String, _ colorOn: Color, _ colorOff: Color) -> some View {
        return AnyView(
            Button(action: {
                buttonStates[count].toggle()
            }) {
                Text(text)
                    .font(.system(size: 30))
                Image(systemName: "balloon.fill")
                    .imageScale(.large)
            }
                .buttonStyle(.borderedProminent)
                .tint(Color.secondary)
                .foregroundStyle(buttonStates[count] ? colorOff : colorOn)
                .frame(maxWidth: .infinity)
        )
    }
    
    var body: some View {
        VStack{
            // Points Tracker
            HStack{
                // Team Boom Tracker
                VStack {
                    Text("Team Boom")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                    Button(action: {
                        teamOne += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(String(teamOne))
                        .font(.title)
                    
                    Button(action: {
                        teamOne -= 1
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 32))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                
                // Team Tarat-Tarat Tracker
                VStack {
                    Text("Team Tarat-Tarat")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                    Button(action: {
                        teamTwo += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(String(teamTwo))
                        .font(.title)
                    
                    Button(action: {
                        teamTwo -= 1
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 32))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                
            }
            .frame(maxHeight: .infinity)
            
            // Popped QBalloons Tracker
            VStack{
                Text("Popped Question Balloons")
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                // 1-6
                HStack {
                    buttonTextIcon(count: 0, text: "1", .yellow, .black)
                    buttonTextIcon(count: 1, text: "2", .yellow, .black)
                    buttonTextIcon(count: 2, text: "3", .yellow, .black)
                    buttonTextIcon(count: 3, text: "4", .yellow, .black)
                    buttonTextIcon(count: 4, text: "5", .yellow, .black)
                    buttonTextIcon(count: 5, text: "6", .yellow, .black)
                }
                .padding()
                
                // 6-12
                HStack {
                    buttonTextIcon(count: 6, text: "7", .yellow, .black)
                    buttonTextIcon(count: 7, text: "8", .yellow, .black)
                    buttonTextIcon(count: 8, text: "9", .yellow, .black)
                    buttonTextIcon(count: 9, text: "10", .yellow, .black)
                    buttonTextIcon(count: 10, text: "11", .yellow, .black)
                    buttonTextIcon(count: 11, text: "12", .yellow, .black)
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
            
            // Popped PBalloons Tracker
            VStack{
                Text("Popped Point Balloons")
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                // 1-6
                HStack {
                    buttonTextIcon(count: 12, text: "13", .red, .black)
                    buttonTextIcon(count: 13, text: "14", .red, .black)
                    buttonTextIcon(count: 14, text: "15", .red, .black)
                    buttonTextIcon(count: 15, text: "16", .red, .black)
                    buttonTextIcon(count: 16, text: "17", .red, .black)
                    buttonTextIcon(count: 17, text: "18", .red, .black)
                }
                .padding()
                
                // 6-12
                HStack {
                    buttonTextIcon(count: 18, text: "19", .red, .black)
                    buttonTextIcon(count: 19, text: "20", .red, .black)
                    buttonTextIcon(count: 20, text: "21", .red, .black)
                    buttonTextIcon(count: 21, text: "22", .red, .black)
                    buttonTextIcon(count: 22, text: "23", .red, .black)
                    buttonTextIcon(count: 23, text: "24", .red, .black)
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
