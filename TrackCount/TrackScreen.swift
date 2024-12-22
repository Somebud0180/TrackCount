//
//  TrackScreen.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData

struct TrackScreen: View {
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var cardNames: [String]
    @Binding var counterStates: [Int]
    @Binding var buttonStates: [Int: Bool]
    
    @Query private var gridStore: [GridStore]
    @Environment(\.modelContext) private var context
    
    func toggleButton(count id: Int, text: String, _ colorOn: Color, _ colorOff: Color) -> some View {
        return AnyView(
            Button(action: {
                buttonStates[id, default: true].toggle()
            }) {
                Text(text)
                    .font(.system(size: 30))
                Image(systemName: "balloon.fill")
                    .imageScale(.large)
            }
                .buttonStyle(.borderedProminent)
                .tint(Color.secondary)
                .foregroundStyle(buttonStates[id, default: true] ? colorOn : colorOff)
                .frame(maxWidth: .infinity)
        )
    }
    
    func counterCard(title: String, modify: Binding<Int>) -> some View {
        return AnyView(
            VStack {
                Text(title)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                Button(action: {modify.wrappedValue += 1}) {
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
                
                Text(String(modify.wrappedValue))
                    .font(.title)
                
                Button(action: {modify.wrappedValue -= 1}) {
                    Image(systemName: "minus")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
    
    var body: some View {
        ScrollView {
            VStack{
                // Points Tracker
                Grid() {
                    GridRow {
                        // Team Boom Tracker
                        counterCard(title: "Team Boom", modify: $teamOne)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Team Boom Tracker
                        counterCard(title: "Team Tarat-Tarat", modify: $teamTwo)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                }
                .frame(maxHeight: .infinity)
                
                // Popped QBalloons Tracker
                VStack{
                    Text("Popped Question Balloons")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                    
                    // 1-6
                    HStack {
                        toggleButton(count: 0, text: "1", .yellow, .black)
                        toggleButton(count: 1, text: "2", .yellow, .black)
                        toggleButton(count: 2, text: "3", .yellow, .black)
                        toggleButton(count: 3, text: "4", .yellow, .black)
                        toggleButton(count: 4, text: "5", .yellow, .black)
                        toggleButton(count: 5, text: "6", .yellow, .black)
                    }
                    .padding()
                    
                    // 6-12
                    HStack {
                        toggleButton(count: 6, text: "7", .yellow, .black)
                        toggleButton(count: 7, text: "8", .yellow, .black)
                        toggleButton(count: 8, text: "9", .yellow, .black)
                        toggleButton(count: 9, text: "10", .yellow, .black)
                        toggleButton(count: 10, text: "11", .yellow, .black)
                        toggleButton(count: 11, text: "12", .yellow, .black)
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
                        toggleButton(count: 12, text: "Ado", .red, .black)
                        toggleButton(count: 13, text: "Ban", .red, .black)
                        toggleButton(count: 14, text: "Cha", .red, .black)
                        toggleButton(count: 15, text: "Don", .red, .black)
                        toggleButton(count: 16, text: "Ens", .red, .black)
                        toggleButton(count: 17, text: "Fru", .red, .black)
                    }
                    .padding()
                    
                    // 6-12
                    HStack {
                        toggleButton(count: 18, text: "Gra", .red, .black)
                        toggleButton(count: 19, text: "Hot", .red, .black)
                        toggleButton(count: 20, text: "Itl", .red, .black)
                        toggleButton(count: 21, text: "JCO", .red, .black)
                        toggleButton(count: 22, text: "Kan", .red, .black)
                        toggleButton(count: 23, text: "Lum", .red, .black)
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
