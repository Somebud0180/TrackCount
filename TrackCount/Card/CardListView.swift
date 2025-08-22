//
//  CardListView.swift
//  TrackCount
//
//  A view containing the list of cards inside a group, given by passing an argument
//

import SwiftUI
import SwiftData

/// A view containing a list of cards in a selected group.
struct CardListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: CardViewModel
    
    // Set variable defaults
    var selectedGroup: DMCardGroup
    @State private var isPresentingCardFormView: Bool = false
    @State private var validationError: [String] = []
    
    /// Initializes the selectedGroup and selectedCard variable for editing.
    /// - Parameters:
    ///   - selectedGroup: accepts DMCardGroup entities, reference for which group to store the card.
    ///   - selectedCard: (optional) accepts DMStoredCard entities, edits the entity that is passed over.
    init(selectedGroup: DMCardGroup) {
        _viewModel = StateObject(wrappedValue: CardViewModel(selectedGroup: selectedGroup))
        self.selectedGroup = selectedGroup
    }
    
    var body: some View {
        NavigationStack {
            // List to preview, rearrange and delete created cards
            List {
                // Check if selectedGroup.cards. is empty and display a message if so
                if (selectedGroup.cards?.isEmpty != nil) {
                    Text("Create a new card to get started")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .transition(.opacity)
                } else {
                    // Display validation error if any
                    if !validationError.isEmpty {
                        Text(viewModel.validationError.joined(separator: ", "))
                            .foregroundStyle(.red)
                            .listRowSeparator(.hidden)
                            .padding()
                    }
                    
                    // Display each card sorted by their id
                    ForEach(selectedGroup.cards!.sorted(by: { $0.index! < $1.index! }), id: \.uuid) { card in
                        Button(action: {
                            viewModel.selectedCard = card
                            viewModel.fetchCard()
                            isPresentingCardFormView.toggle()
                        }) {
                            HStack {
                                Image(systemName: "line.horizontal.3")
                                    .foregroundStyle(.gray)
                                Text(card.title)
                                    .foregroundStyle(Color(.label))
                            }
                        }
                        .listRowSeparator(.hidden)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeCard(card, with: context)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: moveCard)
                    .transition(.slide)
                }
                
                if (selectedGroup.cards?.isEmpty != nil) {
                    Text("Tap on a card to edit, drag to reorder, and swipe to delete")
                        .font(.footnote)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 1), value: selectedGroup.cards)
            
            Button(action: {
                isPresentingCardFormView.toggle()
            }) {
                Text("Create a new card")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitleViewBuilder {
            if (selectedGroup.groupTitle?.isEmpty != nil) {
                Image(systemName: selectedGroup.groupSymbol ?? "")
            } else {
                Text(selectedGroup.groupTitle ?? "")
            }
        }
        .sheet(isPresented: $isPresentingCardFormView, onDismiss: {
            viewModel.resetFields()
        }) {
            CardFormView(viewModel: viewModel)
                .presentationDetents([.fraction(0.6), .fraction(0.99)])
                .onDisappear {
                    viewModel.validationError.removeAll()
                }
        }
    }
    
    /// A function invoked at a list's onMove that handles the movement of the cards in the list.
    /// Copies the cards and stores them to a modifiable variable.
    /// Updates the card's index to reflect the new order.
    private func moveCard(from source: IndexSet, to destination: Int) {
        // Extract the cards in a mutable array
        var mutableCards = selectedGroup.cards?.sorted(by: { $0.index! < $1.index! })
        
        // Perform the move in the mutable array
        mutableCards?.move(fromOffsets: source, toOffset: destination)
        
        // Update the index of the card to reflect the new order
        if let mutableCards {
            for index in mutableCards.indices {
                mutableCards[index].index = index
            }
        }
        
        // Save the changes back to the context
        do {
            if let mutableCards {
                for card in mutableCards {
                    if let selectedCard = selectedGroup.cards?.first(where: { $0.uuid == card.uuid }) {
                        selectedCard.index = card.index // Update the ID in the context
                    }
                }
            }
            try context.save() // Persist the changes
        } catch {
            validationError.append("Failed to save updated order: \(error.localizedDescription)")
        }
    }
}

extension View {
    /// A function that builds the navigation view title based on what is passed into it.
    /// Utilized as it enables the usage of if statements for picking the title.
    @ViewBuilder
    func navigationTitleViewBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    content()
                }
            }
    }
}

#Preview {
    // Sample DMCardGroup to pass into the preview.
    var sampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Card 1", groupSymbol: "star.fill")
    }
    
    CardListView(selectedGroup: sampleGroup)
        .modelContainer(for: DMCardGroup.self)
}
