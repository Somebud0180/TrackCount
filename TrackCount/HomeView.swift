//
//  HomeView.swift
//  TrackCount
//
//  Contains the home screen
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var teamOne = 0
    @State private var teamTwo = 0
    @State private var cardNames: [String] = []
    @State private var counterStates: [Int] = []
    @State private var buttonStates: [Int: Bool] = [:]
    
    @Query private var savedCards: [DMStoredCard]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("TrackCount")
                    .font(.system(size: 64))
                
                Grid(alignment: .center) {
                    NavigationLink(destination: TrackView(teamOne: $teamOne, teamTwo: $teamTwo, cardNames: $cardNames, counterStates: $counterStates, buttonStates: $buttonStates)) {
                        Text("Track It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: GroupListView()) {
                        Text("Edit It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onAppear {
            // Check saved cards and destroy faulty cards
            for card in savedCards {
                checkCardProperties(card: card)
            }
        }
    }
    
    func checkCardProperties(card: DMStoredCard) {
        var errors: [String] = []
        
        // Reflect the properties of the card
        let mirror = Mirror(reflecting: card)
        
        for child in mirror.children {
            if let propertyName = child.label {
                // Check if the value is String and empty
                if child.value is String, let stringValue = child.value as? String, stringValue.isEmpty {
                    errors.append("\(propertyName) is empty")
                }
                // Check if the value is Int and invalid (you can adjust the condition as needed)
                else if child.value is Int, let intValue = child.value as? Int, intValue <= 0 {
                    errors.append("\(propertyName) is zero or invalid")
                }
                // Check if the value is Optional and nil
                else if child.value is Optional<Any>, child.value == nil {
                    errors.append("\(propertyName) is nil")
                }
            }
        }
        
        if !errors.isEmpty {
            print("Card with UUID \(String(describing: card.uuid)) has the following issues: \(errors.joined(separator: ", "))")
            
            do {
                // Remove the card from the context
                context.delete(card)
                
                // Save the context after deletion
                try context.save()
                print("Card with UUID \(String(describing: card.uuid)) has been deleted")
            } catch {
                print("Card with UUID \(String(describing: card.uuid)) has not been deleted")
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DMCardGroup.self)
}
