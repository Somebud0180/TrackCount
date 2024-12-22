//
//  EditView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

struct EditScreen: View {
    @Binding var teamOne: Int
    @Binding var teamTwo: Int
    @Binding var cardNames: [String]
    @Binding var counterStates: [Int]
    @Binding var buttonStates: [Int: Bool]
    
    @Query private var gridStore: [GridStore]
    @Environment(\.modelContext) private var context
    
    @State private var newCardWidth: String = ""
    @State private var newCardColumn: String = ""
    @State private var newCardType: CardType = .counter
    @State private var newCardText: String = ""
    @State private var newButtonText: [String] = Array(repeating: "", count: 1)
    @State private var newCardCount: Int = 1
    @State private var newCardState: [Bool] = []
    @State private var newCardSymbol: String = "star"
    @State private var isPickerPresented: Bool = false
    @State private var validationError: String? = nil
    
    enum CardType: String, Codable, CaseIterable {
        case counter
        case toggle
    }
    
    var body: some View {
        VStack {
            List {
                // Picker for card type
                Picker(selection: $newCardType) {
                    ForEach(CardType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                } label: {
                    Text("Type")
                    Text("Choose a card type")
                }
                
                // Input for card title
                TextField("Set card title", text: $newCardText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .listRowSeparator(.automatic)
                    .padding()
                
                // Stepper for button count if type is toggle
                if newCardType == .toggle {
                    Stepper("Buttons: \(newCardCount)", value: $newCardCount, in: 1...12)
                        .onChange(of: newCardCount) {
                            initButton()
                        }
                    
                    Button(action: {
                        isPickerPresented.toggle()
                    }) {
                        HStack {
                            Text("Symbol: \(newCardSymbol)")
                            Spacer()
                            Image(systemName: newCardSymbol)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $isPickerPresented) {
                        SymbolPicker(selectedSymbol: $newCardSymbol)
                    }
                    
                    ForEach(0..<newCardCount, id: \.self) { index in
                        TextField("Button \(index + 1) Text", text: $newButtonText[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .listRowSeparator(.hidden)
                    }
                }
                
                    // Button to add new card
                Button(action: addCard) {
                    Text("Add")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                    
                    // Display validation error if any
                if let validationError = validationError {
                    Text(validationError)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // Helper function to add card name
    private func addCardName() {
        if !newCardText.isEmpty {
            cardNames.append(newCardText)
            newCardText = ""
            validationError = nil
        } else {
            validationError = "Text cannot be empty"
        }
    }
    
    // Helper function to add card
    private func addCard() {
        if validateGridStoreData(column: Int(newCardColumn) ?? 0, type: newCardType, text: newCardText, buttonText: newButtonText, count: newCardCount, state: newCardState, symbol: newCardSymbol) {
            cardNames.append(newCardText)
            newCardText = ""
            validationError = nil
        } else {
            validationError = "Text cannot be empty"
        }
    }
    
    private func initButton() {
        if newCardCount > newButtonText.count {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
            newCardState.append(contentsOf: Array(repeating: true, count: newCardCount - newCardState.count))
        } else if newCardCount < newButtonText.count {
            newButtonText.removeLast(newButtonText.count - newCardCount)
            newCardState.removeLast(newCardState.count - newCardCount)
        }
    }
}


// Check grid content for validity
func validateGridStoreData(column: Int, type: EditScreen.CardType, text: String, buttonText: [String], count: Int, state: [Bool], symbol: String) -> Bool {
    guard !text.isEmpty else {
        print("Validation Error: Text cannot be empty")
        return false
    }
    return true
}

#Preview {
    ContentView()
}



