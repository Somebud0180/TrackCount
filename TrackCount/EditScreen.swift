//
//  EditView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

struct EditScreen: View {
    // Previous hard-coded implementation
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var cardNames: [String]
    @Binding var counterStates: [Int]
    @Binding var buttonStates: [Int: Bool]
    
    // Query saved cards
    @Query var savedCards: [CardStore]
    @Environment(\.modelContext) private var context
    
    // Set variable defaults
    @State private var newCardIndex: Int = CardIndexManager.getNextAvailable()
    @State private var newCardType: CardStore.Types = .counter
    @State private var newCardTitle: String = ""
    @State private var newButtonText: [String] = Array(repeating: "", count: 1)
    @State private var newCardCount: Int = 1
    @State private var newCardState: [Bool] = Array(repeating: true, count: 1)
    @State private var newCardSymbol: String = ""
    @State private var isPickerPresented: Bool = false
    @State private var validationError: [String] = []
    
    // Format number for Stepper with Text Field hybrid. via https://stackoverflow.com/a/63695046
    static let formatter = NumberFormatter()
    let minLimit = 1
    let maxLimit = 4096
    
    var binding: Binding<String> {
        .init(get: {
            "\(self.newCardCount)"
        }, set: {
            // Ensure the value is an integer and above the minimum limit
            if let value = Int($0), value >= minLimit && value <= maxLimit{
                self.newCardCount = value
            } else if let value = Int($0), value > maxLimit {
                self.newCardCount = maxLimit
            } else {
                self.newCardCount = minLimit  // Reset to minimum if the value is below the limit
            }
        })
    }
    
    var body: some View {
        VStack {
            List {
                // Picker for card type
                Picker(selection: $newCardType) {
                    // Display each types of cards in CardStore
                    ForEach(CardStore.Types.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                } label: {
                    Text("Type")
                    Text("Choose a card type")
                }
                
                // Text field for card title
                TextField("Set card title", text: $newCardTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .listRowSeparator(.hidden)
                
                // Check toggle type then display corresponding fields
                if newCardType == .toggle {
                    HStack{
                        // Create stepper with editable text field. via https://stackoverflow.com/a/63695046
                        Text("Buttons: ")
                        TextField("", text: binding).textFieldStyle(.roundedBorder)
                        Stepper("", value: $newCardCount, in: minLimit...maxLimit)
                    }
                        .listRowSeparator(.hidden)
                        .onChange(of: newCardCount) {
                            initButton()
                        }
                    
                    // Button with selected smybol preview, pops up with SymbolPicker on press
                    Button(action: {
                        isPickerPresented.toggle()
                    }) {
                        HStack {
                            Text("Symbol:")
                            Spacer()
                            Image(systemName: newCardSymbol)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $isPickerPresented) {
                        SymbolPicker(selectedSymbol: $newCardSymbol)
                    }
                    
                    // Create a text field for each button
                    ForEach(0..<newCardCount, id: \.self) { index in
                        TextField("Button \(index + 1) Text", text: $newButtonText[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .listRowSeparator(.hidden)
                    }
                }
                
                // Button to invoke addCard
                Button(action: addCard) {
                    Text("Add")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Display validation errors if any
                if !validationError.isEmpty {
                    Text(validationError.joined(separator: ", ") + " cannot be empty")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            
            // List to preview, rearrange and delete created cards
            List {
                // Display each card sorted by their id, 
                ForEach(savedCards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                    HStack {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.secondary)
                        Text(card.title)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            removeCard(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveCard)
            }
        }
    }
    
    private func moveCard(from source: IndexSet, to destination: Int) {
        // Extract the cards in a mutable array
        var mutableCards = savedCards.sorted(by: { $0.index < $1.index })
        
        // Perform the move in the mutable array
        mutableCards.move(fromOffsets: source, toOffset: destination)
        
        // Update the IDs to reflect the new order
        for index in mutableCards.indices {
            mutableCards[index].index = index
        }
        
        // Save the changes back to the context
        do {
            for card in mutableCards {
                if let existingCard = savedCards.first(where: { $0.uuid == card.uuid }) {
                    existingCard.index = card.index // Update the ID in the context
                }
            }
            try context.save() // Persist the changes
        } catch {
            print("Failed to save updated order: \(error.localizedDescription)")
        }
    }
    
    // Prepare button state and text
    private func initButton() {
        if newCardCount > newButtonText.count {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
        } else if newCardCount < newButtonText.count {
            newButtonText.removeLast(newButtonText.count - newCardCount)
        }
        
        if newCardCount > newCardState.count {
            newCardState.append(contentsOf: Array(repeating: true, count: newCardCount - newCardState.count))
        } else if newCardCount < newCardState.count {
            newCardState.removeLast(newCardState.count - newCardCount)
        }
    }
    
    // Validate card content and save it to the store
    private func addCard() {
        validationError.removeAll()
        if newCardTitle.isEmpty {
            validationError.append("Title")
        }
        
        if newCardType == .toggle && newCardSymbol.isEmpty {
            validationError.append("Button Symbol")
        }
        
        if newCardType == .toggle && newCardCount == 0 {
            validationError.append("Button Card")
        }
        
        if !validationError.isEmpty {
            return
        }
        
        // Create the new card
        let newCard = CardStore(uuid: UUID(),
                                index: newCardIndex,
                                type: newCardType,
                                title: newCardTitle,
                                buttonText: newButtonText,
                                count: newCardCount,
                                state: newCardState,
                                symbol: newCardSymbol)
        
        context.insert(newCard)
        
        do {
            try context.save()
        } catch {
            print("Failed to save new card: \(error.localizedDescription)")
        }
        
        // Reset the input fields
        newCardIndex = CardIndexManager.getNextAvailable()
        newCardTitle = ""
        newButtonText = Array(repeating: "", count: 1)
        newCardCount = 1
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
    }
    
    // Free the ID and remove card from the store
    private func removeCard(_ card: CardStore) {
        do {
            // Remove the card from the context
            context.delete(card)
            
            // Save the context after deletion
            try context.save()
            
            // Free up the ID using the CardIDManager
            CardIndexManager.freeIndex(card.index)
            
            // Update the IDs of remaining cards to fill the gap
            var mutableCards = savedCards.sorted(by: { $0.index < $1.index })
            mutableCards.removeAll { $0.uuid == card.uuid }
            
            // Reassign IDs to remaining cards
            for index in mutableCards.indices {
                mutableCards[index].index = index
            }
            
            // Save the changes back to the context
            try context.save()
            print("Card removed, ID freed, and remaining cards updated.")
            
            newCardIndex = CardIndexManager.getNextAvailable()
            
        } catch {
            print("Failed to remove card and update IDs: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CardStore.self)
}



