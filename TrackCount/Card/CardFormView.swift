//
//  CardFormView.swift
//  TrackCount
//
//  A view containing the card editing interface
//

import SwiftUI

/// A view containing the form for creating or editing a card.
struct CardFormView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CardViewModel
    
    @State private var isSymbolPickerPresented: Bool = false
    @State private var isPresentingRingtonePickerView: Bool = false
    
    @State private var isSaveButtonPressed: Bool = false
    
    struct ValidationVariables: Equatable {
        let title: String
        let modifier: [Int]
        let count: Int
        let symbol: String
        let timerValues: [Int: [Int]]
    }
    
    var body: some View {
        // Create an array containing all variables for the onChange form validation
        var validateVariables: ValidationVariables {
            ValidationVariables(
                title: viewModel.newCardTitle,
                modifier: viewModel.newCardModifier,
                count: viewModel.newCardCount,
                symbol: viewModel.newCardSymbol,
                timerValues: viewModel.newTimerValues
            )
        }
        
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer {
                            formView()
                        }
                    } else {
                        formView()
                    }
                }
                .mask(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white, location: 0.8),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ).blur(radius: 10))
                
                .onChange(of: validateVariables) {
                    if !viewModel.validationError.isEmpty {
                        viewModel.validateForm()
                    }
                }
                
                VStack(spacing: 8) {
                    if !viewModel.warnError.isEmpty {
                        Text(viewModel.warnError.joined(separator: ", "))
                            .foregroundColor(.red)
                            .padding(.top)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isSaveButtonPressed = true
                            saveCard()
                        }
                        
                        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                            isSaveButtonPressed = false
                        }
                    }) {
                        Text(viewModel.selectedCard == nil ? "Add Card" : "Save Changes")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .customRoundedStyle(interactive: true, tint: .blue, externalPressed: isSaveButtonPressed)
                }
                .padding()
            }
            
            .navigationBarTitle(viewModel.selectedCard == nil ? "Create Card" : "Edit Card", displayMode: .inline)
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
                }
            }
        }
    }
    
    private func formView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            pickerFormView()
            
            // Text field for card title
            VStack(alignment: .leading) {
                TextField("Set card title", text: $viewModel.newCardTitle)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                    .errorOverlay("CardTitleEmpty", with: viewModel.validationError)
                    .accessibilityIdentifier("Card Title Field")
                
                // Error message with animation
                errorMessageView("CardTitleEmpty", with: viewModel.validationError, message: "Card title cannot be empty")
            }
            
            let isTimer = (viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom)
            ColorPicker(isTimer ? "Progress Color" : "Button Color:", selection: $viewModel.newCardPrimary, supportsOpacity: false)
            ColorPicker(isTimer ? "Text Color" : "Button Content Color:", selection: $viewModel.newCardSecondary, supportsOpacity: false)
                
            // Check for type and add specific fields for that type
            if viewModel.newCardType == .counter {
                counterFormView()
            } else if viewModel.newCardType == .toggle {
                toggleFormView()
            } else if viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom {
                timerFormView()
            }
        }.padding(.horizontal)
    }
    
    private func counterFormView() -> some View {
        Group {
            VStack(alignment: .leading) {
                Text("Set the button increments:")
                
                Text("Leave at 0 to disable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                
                ForEach(0..<3, id: \.self) { index in
                    VStack(alignment: .leading) {
                        TextField("Modifier \(index + 1)", text: $viewModel.newCardModifierText[index])
                            .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                            .errorOverlay("Modifier\(index)Negative", with: viewModel.validationError, warn: true)
                            .errorOverlay("Modifier\(index)MoreThanMax", with: viewModel.validationError, warn: true)
                            .keyboardType(.numberPad)
                            .onSubmit {
                                viewModel.initCounter()
                            }
                        errorMessageView("Modifier\(index)Negative", with: viewModel.validationError, message: "Modifier cannot be negative", warn: true)
                        errorMessageView("Modifier\(index)MoreThanMax", with: viewModel.validationError, message: "Modifier cannot exceed 100,000", warn: true)
                    }
                }
            }.errorOverlay("ModifierLessThanOne", with: viewModel.validationError, isRectangle: true)
            
            
            errorMessageView("ModifierLessThanOne", with: viewModel.validationError, message: "At least one modifier must be set")
        }
    }
    
    private func pickerFormView() -> some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                // Picker for card type
                if horizontalSizeClass == .regular {
                    Picker(selection: $viewModel.newCardType) {
                        ForEach(DMStoredCard.Types.allCases, id: \.self) { type in
                            Text(type.formattedName).tag(type)
                                .padding(.vertical)
                        }
                    } label: {
                        Text("Type")
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker(selection: $viewModel.newCardType) {
                        ForEach(DMStoredCard.Types.allCases, id: \.self) { type in
                            Text(type.formattedName).tag(type)
                        }
                    } label: {
                        Text("Type")
                    }
                    .pickerStyle(.menu)
                }
                
                // Definition for selected card type
                Text(viewModel.newCardType.typeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func toggleFormView() -> some View {
        // Initialize button count formatter
        let buttonCountFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.allowsFloats = false
            formatter.minimum = (viewModel.minButtonLimit) as NSNumber
            formatter.maximum = (viewModel.maxButtonLimit) as NSNumber
            return formatter
        }()
        
        return Group {
            // A stepper with an editable text field
            VStack(alignment: .leading) {
                HStack {
                    Text("Buttons: ")
                    TextField("", value: $viewModel.newCardCount, formatter: buttonCountFormatter)
                        .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                        .errorOverlay("ButtonExceedsLimits", with: viewModel.validationError)
                        .keyboardType(.numberPad)
                    Stepper("", value: $viewModel.newCardCount, in: viewModel.minButtonLimit...viewModel.maxButtonLimit)
                }
                .onChange(of: viewModel.newCardCount) {
                    viewModel.initButton() // Create new text field for each toggle
                }
                
                ZStack(alignment: .leading) {
                    errorMessageView("ButtonLessThanMin", with: viewModel.validationError, message: "There must be at least 1 button")
                    errorMessageView("ButtonMoreThanMax", with: viewModel.validationError, message: "There can be at most 4,096 buttons")
                }
            }
            
            
            // A symbol preview/picker
            VStack(alignment: .leading) {
                Button(action: {
                    isSymbolPickerPresented = true
                }) {
                    HStack {
                        Text("Button Symbol:")
                        Spacer()
                        Image(systemName: viewModel.newCardSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                    .errorOverlay("SymbolEmpty", with: viewModel.validationError)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $isSymbolPickerPresented) {
                    SymbolPickerView(viewBehaviour: .tapToSelect, selectedSymbol: $viewModel.newCardSymbol)
                        .presentationDetents([.fraction(0.99)])
                }
                
                errorMessageView("SymbolEmpty", with: viewModel.validationError, message: "A symbol is required")
            }
            
            
            ForEach(0..<viewModel.newButtonText.count, id: \.self) { index in
                if index < viewModel.newButtonText.count {
                    let characterLimit = viewModel.buttonTextLimit
                    
                    TextField("Button \(index + 1) Text", text: $viewModel.newButtonText[index])
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                        .onChange(of: viewModel.newButtonText[index]) {
                            if viewModel.newButtonText[index].count > characterLimit {
                                viewModel.newButtonText[index] = String(viewModel.newButtonText[index].trimmingCharacters(in: .whitespaces))
                                viewModel.newButtonText[index] = String(viewModel.newButtonText[index].prefix(characterLimit))
                            }
                        }
                        .onSubmit {
                            viewModel.newButtonText[index] = viewModel.newButtonText[index].trimmingCharacters(in: .whitespaces)
                        }
                }
            }
        }
    }
    
    private func timerFormView() -> some View {
        // Initialize timer count formatter
        let timerCountFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.allowsFloats = false
            formatter.minimum = (viewModel.minTimerAmount) as NSNumber
            formatter.maximum = (viewModel.maxTimerAmount) as NSNumber
            return formatter
        }()
        
        return Group {
            Button(action: {
                isPresentingRingtonePickerView = true
            }) {
                HStack {
                    Text("Timer Ringtone")
                    
                    Spacer()
                    
                    Text("\(viewModel.newCardRingtone.isEmpty ? "Default" : viewModel.newCardRingtone)")
                        .foregroundStyle(.secondary)
                }
                .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
            }
            .buttonStyle(PlainButtonStyle())
            
            .sheet(isPresented: $isPresentingRingtonePickerView) {
                RingtonePickerView(setVariable: $viewModel.newCardRingtone, fromSettings: false)
            }
            
            if viewModel.newCardType == .timer {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Timers: ")
                        TextField("", value: $viewModel.newCardCount, formatter: timerCountFormatter)
                            .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                            .errorOverlay("TimerExceedsLimits", with: viewModel.validationError)
                            .keyboardType(.numberPad)
                        Stepper("", value: $viewModel.newCardCount, in: viewModel.minTimerAmount...viewModel.maxTimerAmount)
                    }
                    .onChange(of: viewModel.newCardCount) {
                        viewModel.initTimer()
                    }
                    
                    errorMessageView("TimerExceedsLimits", with: viewModel.validationError, message: "You can only set 1 to 4 timers")
                }
                
                
                ForEach(0..<viewModel.newCardCount, id: \.self) { index in
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Timer \(index + 1): ")
                                .padding(.leading)
                            TimeWheelPickerView(
                                timerArray: Binding(
                                    get: { viewModel.newTimerValues[index] ?? [0, 0, 0] },
                                    set: { newValue in
                                        viewModel.updateTimerValue(
                                            index: index,
                                            hours: newValue[0],
                                            minutes: newValue[1],
                                            seconds: newValue[2]
                                        )
                                    }
                                )
                            )
                            .padding(.horizontal)
                            .frame(maxHeight: 150)
                        }
                        .errorOverlay("Timer\(index)LessThanMin", with: viewModel.validationError, isRectangle: true)
                        .errorOverlay("Timer\(index)MoreThanMax", with: viewModel.validationError, isRectangle: true)
                        
                        ZStack(alignment: .leading) {
                            errorMessageView("Timer\(index)LessThanMin", with: viewModel.validationError, message: "Timer must be greater than a second")
                            errorMessageView("Timer\(index)MoreThanMax", with: viewModel.validationError, message: "Timer must be less than a day")
                        }
                    }
                }
            }
            
            Spacer(minLength: 64)
        }
    }
    
    /// A  function that saves the current card and dismisses the screen.
    /// Contains some safeguards to avoid crashes.
    private func saveCard() {
        // Resign the first responder to ensure that any active text fields commit their changes.
        // This prevents a crash that occurs when saving while a text field is still being edited.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Defer the save action to the next run loop to ensure all UI updates are completed.
        // This helps in making sure that the text fields have updated their bound variables before saving.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.saveCard(with: context)
            
            // When attempting save, perform counter card increment min max application
            for (i, value) in viewModel.newCardModifierText.enumerated() {
                let intValue = Int(value) ?? 0
                let clamped = min(max(intValue, 0), viewModel.maxModifierLimit)
                viewModel.newCardModifierText[i] = "\(clamped)"
            }
                
            if viewModel.validationError.isEmpty && viewModel.warnError.isEmpty {
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

