//
//  CardFormView.swift
//  TrackCount
//
//  A view containing the card editing interface
//

import SwiftUI

/// A view containing the form for creating or editing a card
struct CardFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CardViewModel
    
    @State private var isSymbolPickerPresented: Bool = false
    
    /// Initializes the selectedGroup and selectedCard variable for editing
    /// - Parameters:
    ///   - selectedGroup: accepts DMCardGroup entities, reference for which group to store the card
    ///   - selectedCard: (optional) accepts DMStoredCard entities, edits the entity that is passed over
    init(selectedGroup: DMCardGroup, selectedCard: DMStoredCard? = nil) {
        _viewModel = StateObject(wrappedValue: CardViewModel(selectedGroup: selectedGroup, selectedCard: selectedCard))
    }
    
    // Format number for Stepper with Text Field hybrid. via https://stackoverflow.com/a/63695046
    static let formatter = NumberFormatter()
    
    // Binding to manage the TextField input for newCardCount
    var countBinding: Binding<String> {
        Binding<String>(
            get: {
                "\(self.viewModel.newCardCount)"
            },
            set: {
                // Ensure the value is an integer and within limits
                if let value = Int($0), value >= viewModel.minButtonLimit && value <= viewModel.maxButtonLimit {
                    self.viewModel.newCardCount = value
                } else if let value = Int($0), value > viewModel.minButtonLimit {
                    self.viewModel.newCardCount = viewModel.maxButtonLimit // Set to max if the value is above the limit
                } else {
                    self.viewModel.newCardCount = viewModel.minButtonLimit  // Reset to minimum if the value is below the limit
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Picker for card type
                Picker(selection: $viewModel.newCardType) {
                    ForEach(DMStoredCard.Types.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                } label: {
                    Text("Type")
                }
                .listRowSeparator(.hidden)
                
                // Text field for card title
                TextField("Set card title", text: $viewModel.newCardTitle)
                    .customRoundedStyle()
                    .listRowSeparator(.hidden)
                
                // Check type for toggle to add specific editing fields
                if viewModel.newCardType == .toggle {
                    // A stepper with an editable text field
                    HStack {
                        Text("Buttons: ")
                        TextField("", value: $viewModel.newCardCount, formatter: NumberFormatter())
                            .customRoundedStyle()
                            .keyboardType(.numberPad)
                        Stepper("", value: $viewModel.newCardCount, in: viewModel.minButtonLimit...viewModel.maxButtonLimit)
                    }
                    .onChange(of: viewModel.newCardCount) {
                        viewModel.initButton(with: context) // Create new text field for each toggle
                    }
                    .listRowSeparator(.hidden)
                    
                    // A symbol preview/picker
                    Button(action: {
                        isSymbolPickerPresented.toggle()
                    }) {
                        HStack {
                            Text("Button Symbol:")
                            Spacer()
                            Image(systemName: viewModel.newCardSymbol)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                        .customRoundedStyle()
                    }
                    .listRowSeparator(.hidden)
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $isSymbolPickerPresented) {
                        SymbolPicker(behaviour: .tapToSelect, selectedSymbol: $viewModel.newCardSymbol)
                            .presentationDetents([.fraction(0.99)])
                    }
                    
                    ForEach(0..<viewModel.newButtonText.count, id: \.self) { index in
                        TextField("Button \(index + 1) Text", text: $viewModel.newButtonText[index])
                            .customRoundedStyle()
                            .listRowSeparator(.hidden)
                    }
                }
                
                Button(action: {
                    viewModel.saveCard(with: context)
                    if viewModel.selectedCard != nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(viewModel.selectedCard == nil ? "Add Card" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .listRowSeparator(.hidden)
                
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError.joined(separator: ", "))
                        .foregroundColor(.red)
                        .listRowSeparator(.hidden)
                        .padding()
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(viewModel.selectedCard == nil ? "Add Card" : "Edit Card", displayMode: .inline)
            .navigationBarItems(trailing: Button("Dismiss") {
                dismiss()
            })
            .onAppear {
                viewModel.initEditCard(with: context)
            }
        }
    }
}

#Preview {
    // Sample DMCardGroup to pass into the preview
    var sampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Card 1", groupSymbol: "star.fill")
    }
    
    CardFormView(selectedGroup: sampleGroup)
        .modelContainer(for: DMCardGroup.self)
}
