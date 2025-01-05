//
//  CardFormView.swift
//  TrackCount
//
//  A view containing the card editing interface
//

import SwiftUI

/// A view containing the form for creating or editing a card.
struct CardFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CardViewModel
    
    @State private var isSymbolPickerPresented: Bool = false
    
    /// Format number for Stepper with Text Field hybrid. via https://stackoverflow.com/a/63695046.
    static let formatter = NumberFormatter()
    
    /// Binding to manage the TextField input for newCardCount.
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
                
                
                ColorPicker("Button Color:", selection: $viewModel.newCardPrimary, supportsOpacity: false)
                    .listRowSeparator(.hidden)
                
                ColorPicker("Button Content Color:", selection: $viewModel.newCardSecondary, supportsOpacity: false)
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
                        viewModel.initButton() // Create new text field for each toggle
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
                        SymbolPicker(viewBehaviour: .tapToSelect, selectedSymbol: $viewModel.newCardSymbol)
                            .presentationDetents([.fraction(0.99)])
                    }
                    
                    ForEach(0..<viewModel.newButtonText.count, id: \.self) { index in
                        if index < viewModel.newButtonText.count {
                            let characterLimit = viewModel.buttonTextLimit
                            
                            ZStack(alignment: .bottomTrailing) {
                                TextField("Button \(index + 1) Text", text: $viewModel.newButtonText[index])
                                    .customRoundedStyle()
                                    .onChange(of: viewModel.newButtonText[index]) {
                                        if viewModel.newButtonText[index].count > characterLimit {
                                            viewModel.newButtonText[index] = String(viewModel.newButtonText[index].trimmingCharacters(in: .whitespaces))
                                            viewModel.newButtonText[index] = String(viewModel.newButtonText[index].prefix(characterLimit))
                                        }
                                    }
                                    .onSubmit {
                                        viewModel.newButtonText[index] = viewModel.newButtonText[index].trimmingCharacters(in: .whitespaces)
                                    }
                                
                                Text("\(viewModel.newButtonText[index].count)/\(characterLimit)")
                                    .padding([.trailing], 3)
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                
                Button(action: {
                    saveCard()
                }) {
                    Text(viewModel.selectedCard == nil ? "Add Card" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .listRowSeparator(.hidden)
                
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError.joined(separator: ", "))
                        .foregroundStyle(.red)
                        .listRowSeparator(.hidden)
                        .padding()
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(viewModel.selectedCard == nil ? "Add Card" : "Edit Card", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                    }
                }
            }
        }
    }
    
    func buttonTextField() {
        
    }
    
    /// A  function that saves the current card and dismisses the screen.
    /// Contains some safeguards to avoid crashes.
    private func saveCard() {
        // Resign the first responder to ensure that any active text fields commit their changes.
        // This prevents a crash that occurs when saving while a text field is still being edited.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Defer the save action to the next run loop to ensure all UI updates are completed.
        // This helps in making sure that the text fields have updated their bound variables before saving.
        DispatchQueue.main.async {
            viewModel.saveCard(with: context)
            if viewModel.validationError.isEmpty {
                dismiss()
            }
        }
    }
}

#Preview {
    // Sample DMCardGroup to pass into the preview
    var sampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Card 1", groupSymbol: "star.fill")
    }
    
    // Sample CardViewModel to pass into the preview
    let testViewModel = CardViewModel(selectedGroup: sampleGroup)
    
    CardFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
