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
    @State private var isPresentingRingtonePickerView: Bool = false
    
    /// Format number for Stepper with Text Field hybrid. via https://stackoverflow.com/a/63695046.
    static let formatter = NumberFormatter()

    private let positiveIntFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 0
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading) {
                    // Picker for card type
                    Picker(selection: $viewModel.newCardType) {
                        ForEach(DMStoredCard.Types.allCases, id: \.self) { type in
                            Text(type.formattedName).tag(type)
                        }
                    } label: {
                        Text("Type")
                    }
                    
                    // Definition for selected card type
                    Text(viewModel.newCardType.typeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
                
                // Text field for card title
                TextField("Set card title", text: $viewModel.newCardTitle)
                    .customRoundedStyle()
                    .listRowSeparator(.hidden)
                
                let isTimer = (viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom)
                
                ColorPicker(isTimer ? "Progress Color" : "Button Color:", selection: $viewModel.newCardPrimary, supportsOpacity: false)
                    .listRowSeparator(.hidden)
                
                ColorPicker(isTimer ? "Text Color" : "Button Content Color:", selection: $viewModel.newCardSecondary, supportsOpacity: false)
                    .listRowSeparator(.hidden)
                
                // Check for type and add specific fields for that type
                if viewModel.newCardType == .counter {
                    VStack(alignment: .leading) {
                        Text("Set the button increments:")
                                                    
                        Text("Leave at 0 to disable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowSeparator(.hidden)

                    TextField("Modifier 1", value: $viewModel.newCardModifier1, formatter: positiveIntFormatter)
                        .customRoundedStyle()
                        .listRowSeparator(.hidden)
                    
                    TextField("Modifier 2", value: $viewModel.newCardModifier2, formatter: positiveIntFormatter)
                        .customRoundedStyle()
                        .listRowSeparator(.hidden)
                    
                    TextField("Modifier 3", value: $viewModel.newCardModifier3, formatter: positiveIntFormatter)
                        .customRoundedStyle()
                        .listRowSeparator(.hidden)
                } else if viewModel.newCardType == .toggle {
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
                    }
                    .listRowSeparator(.hidden)
                    .customRoundedStyle()
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $isSymbolPickerPresented) {
                        SymbolPickerView(viewBehaviour: .tapToSelect, selectedSymbol: $viewModel.newCardSymbol)
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
                } else if viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom {
                    Button(action: {
                        isPresentingRingtonePickerView.toggle()
                    }) {
                        Text("Timer Ringtone")
                        
                        Spacer()
                        
                        Text("\(viewModel.newCardRingtone.isEmpty ? "Default" : viewModel.newCardRingtone)")
                            .foregroundStyle(.secondary)
                    }
                    .listRowSeparator(.hidden)
                    .customRoundedStyle()
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $isPresentingRingtonePickerView) {
                        RingtonePickerView(setVariable: $viewModel.newCardRingtone, fromSettings: false)
                    }
                    
                    if viewModel.newCardType == .timer {
                        HStack {
                            Text("Timers: ")
                            TextField("", value: $viewModel.newCardCount, formatter: NumberFormatter())
                                .customRoundedStyle()
                                .keyboardType(.numberPad)
                            Stepper("", value: $viewModel.newCardCount, in: viewModel.minTimerAmount...viewModel.maxTimerAmount)
                        }
                        .onChange(of: viewModel.newCardCount) {
                            viewModel.initTimer()
                        }
                        .listRowSeparator(.hidden)
                        
                        
                        ForEach(0..<viewModel.newCardTimer.count, id: \.self) { index in
                            HStack {
                                Text("Timer \(index + 1): ")
                                TimeWheelPickerView(totalSeconds: $viewModel.newCardTimer[index],
                                               isPickerMoving: $viewModel.isPickerMoving[index])
                            }
                            .padding(.horizontal)
                            .frame(maxHeight: 150)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(viewModel.selectedCard == nil ? "Add Card" : "Edit Card", displayMode: .inline)
            .onChange(of: viewModel.newCardType) {
                viewModel.initTypes(for: .switchType)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(viewModel.isPickerMoving.contains(true))
                }
            }
            
            if !viewModel.validationError.isEmpty {
                Text("\(viewModel.validationError.joined(separator: ", ")).")
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                saveCard()
            }) {
                Text(viewModel.selectedCard == nil ? "Add Card" : "Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(viewModel.isPickerMoving.contains(true))
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

extension DMStoredCard.Types {
    var formattedName: String {
        let components = self.rawValue.components(separatedBy: "_")
        if components.count > 1 {
            let firstWord = components[0].capitalized
            let restWords = components[1].capitalized
            return "\(firstWord) (\(restWords))"
        }
        return self.rawValue.capitalized
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
