//
//  CardList.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 12/26/24.
//

import SwiftUI
import SwiftData

struct CardList: View {
    @Query var savedCards: [CardStore]
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CardViewModel()
    
    // Set variable defaults
    @State private var isCardFormPresented: Bool = false
    @State private var validationError: [String] = []
    @State private var selectedCard: CardStore? = nil
    
    var body: some View {
        List {
            // Check if savedCards is empty and display a message if so
            if savedCards.isEmpty {
                Text("No cards created yet :O")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            } else {
                // Display each card sorted by their id
                ForEach(savedCards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                    HStack {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.secondary)
                        Text(card.title)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.removeCard(card, with: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        selectedCard = card
                        isCardFormPresented.toggle()
                    }
                }
                .onMove { indices, newOffset in
                    viewModel.moveCard(from: indices, to: newOffset, with: context)
                }
            }
            
            Button(action: {isCardFormPresented.toggle()}) {
                Text("Create a new card")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding()
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .sheet(isPresented: $isCardFormPresented) {
            CardForm(selectedCard)
                .presentationDetents([.fraction(0.99)])
                .onDisappear {
                    selectedCard = nil
                }
        }
    }
}

#Preview {
    CardList()
        .modelContainer(for: CardStore.self)
}
