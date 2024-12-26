//
//  CardForm.swift
//  TrackCount
//
//  The card editing interface
//

import SwiftUI

struct CardForm: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CardViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var isPickerPresented: Bool = false
    
    // Initializer accepting an optional existingCard
    init(_ existingCard: CardStore? = nil) {
        // Initialize viewModel with existingCard
        _viewModel = StateObject(wrappedValue: CardViewModel(existingCard: existingCard))
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
                    ForEach(CardStore.Types.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                } label: {
                    Text("Type")
                }
                
                // Text field for card title
                TextField("Set card title", text: $viewModel.newCardTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .listRowSeparator(.hidden)
                
                // Check type for toggle to add specific editing fields
                if viewModel.newCardType == .toggle {
                    // A stepper with an editable text field
                    HStack {
                        Text("Buttons: ")
                        TextField("", value: $viewModel.newCardCount, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Stepper("", value: $viewModel.newCardCount, in: viewModel.minButtonLimit...viewModel.maxButtonLimit)
                    }
                    .onChange(of: viewModel.newCardCount) {
                        viewModel.initButton(with: context) // Create new text field for each toggle
                    }
                    
                    // A symbol preview/picker
                    Button(action: {
                        isPickerPresented.toggle()
                    }) {
                        HStack {
                            Text("Symbol:")
                            Spacer()
                            Image(systemName: viewModel.newCardSymbol)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $isPickerPresented) {
                        SymbolPicker(selectedSymbol: $viewModel.newCardSymbol)
                            .presentationDetents([.fraction(0.99)])
                    }
                    
                    ForEach(0..<viewModel.newCardCount, id: \.self) { index in
                        TextField("Button \(index + 1) Text", text: $viewModel.newButtonText[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .listRowSeparator(.hidden)
                    }
                }
                
                Button(action: {
                    viewModel.saveCard(with: context)
                    if viewModel.existingCard != nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(viewModel.existingCard == nil ? "Add Card" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError.joined(separator: ", ") + " cannot be empty")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationBarTitle(viewModel.existingCard == nil ? "Create Card" : "Edit Card", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {presentationMode.wrappedValue.dismiss()})
            .onAppear {
                viewModel.initEditCard(with: context)
            }
        }
    }
}

#Preview {
    CardForm()
        .modelContainer(for: CardStore.self)
}
