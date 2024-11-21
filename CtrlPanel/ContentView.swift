//
//  ContentView.swift
//  CtrlPanel
//
//  Created by Ethan John Lagera on 11/20/24.
//

import SwiftUI

struct ContentView: View {
    @State private var boomScore = 0
    @State private var taratScore = 0
    @State private var questionBalloonStates: [Bool] = Array(repeating: false, count: 13)
    @State private var pointBalloonStates: [Bool] = Array(repeating: false, count: 13)
    
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
                        boomScore += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(String(boomScore))
                        .font(.title)
                    
                    Button(action: {
                        boomScore -= 1
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 32, weight: .regular))
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
                        taratScore += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(String(taratScore))
                        .font(.title)
                    
                    Button(action: {
                        taratScore -= 1
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 32, weight: .regular))
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
                    Button(action: {
                        questionBalloonStates[1].toggle()
                    }) {
                        Text("1")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[1] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[2].toggle()
                    }) {
                        Text("2")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[2] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[3].toggle()
                    }) {
                        Text("3")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[3] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[4].toggle()
                    }) {
                        Text("4")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[4] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[5].toggle()
                    }) {
                        Text("5")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[5] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[6].toggle()
                    }) {
                        Text("6")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[6] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                // 6-12
                HStack {
                    Button(action: {
                        questionBalloonStates[7].toggle()
                    }) {
                        Text("7")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[7] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[8].toggle()
                    }) {
                        Text("8")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[8] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[9].toggle()
                    }) {
                        Text("9")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[9] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[10].toggle()
                    }) {
                        Text("10")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[10] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[11].toggle()
                    }) {
                        Text("11")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[11] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        questionBalloonStates[12].toggle()
                    }) {
                        Text("12")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(questionBalloonStates[12] ? .black : .yellow)
                    .frame(maxWidth: .infinity)
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
                    Button(action: {
                        pointBalloonStates[1].toggle()
                    }) {
                        Text("1")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[1] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[2].toggle()
                    }) {
                        Text("2")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[2] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[3].toggle()
                    }) {
                        Text("3")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[3] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[4].toggle()
                    }) {
                        Text("4")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[4] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[5].toggle()
                    }) {
                        Text("5")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[5] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[6].toggle()
                    }) {
                        Text("6")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[6] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                // 6-12
                HStack {
                    Button(action: {
                        pointBalloonStates[7].toggle()
                    }) {
                        Text("7")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[7] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[8].toggle()
                    }) {
                        Text("8")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[8] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[9].toggle()
                    }) {
                        Text("9")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[9] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[10].toggle()
                    }) {
                        Text("10")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[10] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[11].toggle()
                    }) {
                        Text("11")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[11] ? .black : .pink)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        pointBalloonStates[12].toggle()
                    }) {
                        Text("12")
                            .font(.system(size: 30))
                        Image(systemName: "balloon.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.secondary)
                    .foregroundStyle(pointBalloonStates[12] ? .black : .pink)
                    .frame(maxWidth: .infinity)
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
