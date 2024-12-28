//
//  HomeView.swift
//  TrackCount
//
//  Contains the home screen
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query private var savedGroups: [DMCardGroup]
    @State var animateGradient: Bool = false
    var gradientColors: [Color] {
        colorScheme == .light ? [.white, .blue] : [.black, .gray]
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("TrackCount")
                    .font(.system(size: 64))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Grid(alignment: .center) {
                    NavigationLink(destination: GroupListView(viewBehaviour: .view)) {
                        Text("Track It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: GroupListView(viewBehaviour: .edit)) {
                        Text("Edit It")
                            .font(.system(size: 32))
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .hueRotation(.degrees(animateGradient ? 45 : 0))
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever())
                    {
                        animateGradient.toggle()
                    }
                }
            }
        }
        .onAppear {
            // Check saved cards and destroy faulty cards
            for group in savedGroups {
                for card in group.cards {
                    checkCardProperties(card: card)
                }
            }
        }
    }
    
    /// A function that checks the contents of a card for any issues and deletes it.
    /// - Parameter card: Accepts a DMStoredCard entity, the card that will be checked.
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
