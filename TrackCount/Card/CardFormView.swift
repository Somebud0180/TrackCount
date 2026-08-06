//
//  CardFormView.swift
//  TrackCount
//
//  A view containing the card editing interface
//

import SwiftUI
import SwiftData

/// A view containing the form for creating or editing a card.
struct CardFormView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CardViewModel
    
    @State private var saveSectionHeight: CGFloat = 0
    @State private var isSymbolPickerPresented: Bool = false
    @State private var isPresentingRingtonePickerView: Bool = false
    @State private var isPresentingListInputView: Bool = false
    
    @State private var isSaveButtonPressed: Bool = false
    @State private var isListApplyButtonPressed: Bool = false
    @State private var listInputText: String = ""
    @State private var modifyExistingText: Bool = false
    
    
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
                formView()
                .padding(.top, -24)
                .padding(.bottom, saveSectionHeight + 8)
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
                    .customRoundedGlass(interactive: true, tint: .blue, externalPressed: isSaveButtonPressed)
                }
                .padding()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                saveSectionHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size) {
                                saveSectionHeight = proxy.size.height
                            }
                    })
            }
            .navigationBarTitle(viewModel.selectedCard == nil ? "Create Card" : "Edit Card", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                }
            }
        }
        .sheet(isPresented: $isSymbolPickerPresented) {
            SymbolPickerView(viewBehaviour: .tapToSelect, selectedSymbol: $viewModel.newCardSymbol)
                .presentationDetents([.fraction(0.95)])
        }
        .sheet(isPresented: $isPresentingListInputView) {
            listInputView
                .presentationDetents([.fraction(0.95)])
        }
        .onChange(of: viewModel.newCardType) {
            viewModel.initTypes(for: .switchType)
        }
    }
    
    private var listInputView: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    Text("Enter text with each line corresponding to a button")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    
                    HStack {
                        Button(action: {
                            listInputText = ""
                        }) {
                            Label("Clear All", systemImage: "xmark.circle")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .customRoundedGlass(tint: colorScheme == .dark ? .gray : .white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            // Toggle the modify existing state
                            modifyExistingText.toggle()
                            
                            if modifyExistingText {
                                // Populate with existing text when toggled on
                                var existingTexts = [String]()
                                for text in viewModel.newButtonText {
                                    existingTexts.append(text)
                                }
                                listInputText = existingTexts.joined(separator: "\n")
                            } else {
                                // Clear the text when toggled off
                                listInputText = ""
                            }
                        }) {
                            Label("Modify Existing", systemImage: modifyExistingText ? "pencil.line" : "pencil.slash")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .customRoundedGlass(tint: modifyExistingText ? .blue : (colorScheme == .dark ? .gray : .white))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    TextEditor(text: $listInputText)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: usesLiquidGlass ? 16 : 8)
                                .stroke(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray3), lineWidth: 1)
                        )
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .cornerRadius(usesLiquidGlass ? 16 : 8)
                    
                    Spacer(minLength: 80) // Extra space to avoid being hidden by the button
                }
                .padding(12)
                .mask(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white, location: 0.8),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ).blur(radius: 10))
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isListApplyButtonPressed = true
                        processListInput()
                        listInputText = ""
                        modifyExistingText = false
                    }
                    withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                        isListApplyButtonPressed = false
                        isPresentingListInputView = false
                    }
                }) {
                    Text("Apply")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                }
                .customRoundedGlass(interactive: true, tint: .blue, externalPressed: isListApplyButtonPressed)
                .disabled(listInputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.vertical, 8)
                .padding()
            }
            .navigationTitle("Button List Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresentingListInputView = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        processListInput()
                        listInputText = ""
                        modifyExistingText = false
                        isPresentingListInputView = false
                    }
                    .disabled(listInputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                // When the sheet appears, populate with existing text if modify is active
                if modifyExistingText {
                    var existingTexts = [String]()
                    for text in viewModel.newButtonText {
                        existingTexts.append(text)
                    }
                    listInputText = existingTexts.joined(separator: "\n")
                } else {
                    // Clear the text if modify is inactive
                    listInputText = ""
                }
            }
        }
    }
    
    private func formView() -> some View {
        Form {
            Section {
                // Text field for card title
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Set card title", text: $viewModel.newCardTitle)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("Card Title Field")
                    
                    // Error message with animation
                    errorMessageView("CardTitleEmpty", with: viewModel.validationError, message: "Card title cannot be empty")
                }
                
                typePickerView()
            }
            
            Section(header: Text("Colors")) {
                let isTimer = (viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom)
                ColorPicker(isTimer ? "Progress Color" : "Button Color:", selection: $viewModel.newCardPrimary, supportsOpacity: false)
                ColorPicker(isTimer ? "Text Color" : "Button Content Color:", selection: $viewModel.newCardSecondary, supportsOpacity: false)
            }
            
            // Check for type and add specific fields for that type
            if viewModel.newCardType == .counter {
                counterFormView()
            } else if viewModel.newCardType == .toggle {
                toggleFormView()
            } else if viewModel.newCardType == .timer || viewModel.newCardType == .timer_custom {
                Section {
                    timerFormView()
                }
            }
        }
    }
    
    private func typePickerView() -> some View {
        // Picker for card type
        VStack(alignment: .leading, spacing: 8) {
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
    
    private func counterFormView() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set the button increments:")
                
                Text("Leave at 0 to disable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach($viewModel.newCardModifierItems) { $item in
                let index = viewModel.newCardModifierItems.firstIndex(where: { $0.id == item.id }) ?? 0
                HStack {
                    VStack(alignment: .leading) {
                        TextField("Modifier \(index + 1)", text: $item.text)
                            .errorOverlay("Modifier\(index)Negative", with: viewModel.validationError, warn: true)
                            .errorOverlay("Modifier\(index)MoreThanMax", with: viewModel.validationError, warn: true)
                            .keyboardType(.numberPad)
                            .onChange(of: item.text) {
                                viewModel.initCounter()
                            }
                            .onSubmit {
                                viewModel.initCounter()
                            }
                        errorMessageView("Modifier\(index)Negative", with: viewModel.validationError, message: "Modifier cannot be negative", warn: true)
                        errorMessageView("Modifier\(index)MoreThanMax", with: viewModel.validationError, message: "Modifier cannot exceed 100,000", warn: true)
                    }
                    
                    Image(systemName: "line.horizontal.3")
                        .foregroundStyle(.secondary)
                }
            }
            .onMove(perform: viewModel.moveModifier)
            
            errorMessageView("ModifierLessThanOne", with: viewModel.validationError, message: "At least one modifier must be set")
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
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    // A stepper with an editable text field
                    HStack {
                        Text("Buttons: ")
                        TextField("", value: $viewModel.newCardCount, formatter: buttonCountFormatter)
                            .errorOverlay("ButtonExceedsLimits", with: viewModel.validationError)
                            .keyboardType(.numberPad)
                        Stepper("", value: $viewModel.newCardCount, in: viewModel.minButtonLimit...viewModel.maxButtonLimit)
                    }
                    .onChange(of: viewModel.newCardCount) {
                        viewModel.initButton() // Create new text field for each toggle
                    }
                    
                    errorMessageView("ButtonLessThanMin", with: viewModel.validationError, message: "There must be at least 1 button")
                    
                    errorMessageView("ButtonMoreThanMax", with: viewModel.validationError, message: "There can be at most 4,096 buttons")
                }
                
                // A symbol preview/picker
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        isSymbolPickerPresented = true
                    }) {
                        HStack {
                            Text("Button Symbol:")
                            Spacer()
                            if viewModel.newCardSymbol.isEmpty {
                                Text("Select")
                            } else {
                                Image(systemName: viewModel.newCardSymbol)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .errorOverlay("SymbolEmpty", with: viewModel.validationError)
                    }
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .buttonStyle(.plain)
                    
                    errorMessageView("SymbolEmpty", with: viewModel.validationError, message: "A symbol is required")
                }
                
                // Quick actions
                HStack {
                    Button(action: {
                        // Clear all button texts
                        for i in 0..<viewModel.newButtonText.count {
                            viewModel.newButtonText[i] = ""
                        }
                    }) {
                        Label("Clear All", systemImage: "xmark.circle")
                            .foregroundStyle(colorScheme == . dark ? .white : .black)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Menu {
                        // Show autofill options
                        Button("Number Prefix") {
                            addNumberPrefixes()
                        }
                        
                        Button("List Input") {
                            isPresentingListInputView = true
                        }
                    } label: {
                        Label("Autofill", systemImage: "wand.and.stars")
                            .foregroundStyle(colorScheme == . dark ? .white : .black)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section {
                ForEach(0..<viewModel.newButtonText.count, id: \.self) { index in
                    if index < viewModel.newButtonText.count {
                        let characterLimit = viewModel.buttonTextLimit
                        
                        TextField("Button \(index + 1) Text", text: $viewModel.newButtonText[index])
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
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
            for i in 0..<viewModel.newCardModifierItems.count {
                let value = viewModel.newCardModifierItems[i].text
                let intValue = Int(value) ?? 0
                let clamped = min(max(intValue, 0), viewModel.maxModifierLimit)
                viewModel.newCardModifierItems[i].text = "\(clamped)"
            }
            
            if viewModel.validationError.isEmpty && viewModel.warnError.isEmpty {
                dismiss()
            }
        }
    }
    
    /// Adds a number prefix to button texts that don't already have one
    /// Skips both buttons with existing number prefixes and buttons that are just numbers
    private func addNumberPrefixes() {
        for i in 0..<viewModel.newButtonText.count {
            let currentText = viewModel.newButtonText[i].trimmingCharacters(in: .whitespaces)
            
            // Skip if the text already has a number prefix like "1. ", "2- ", etc.
            if currentText.range(of: "^\\d+[.\\-):] ", options: .regularExpression) == nil {
                // Skip if the text is just a number like "1", "2", etc.
                if Int(currentText) == nil {
                    // Button doesn't have a number prefix and is not just a number, so add a prefix
                    if !currentText.isEmpty {
                        viewModel.newButtonText[i] = "\(i + 1). \(currentText)"
                    } else {
                        viewModel.newButtonText[i] = "\(i + 1)"
                    }
                }
            }
        }
    }
    
    /// Processes the list input text to populate button texts
    /// If modifyExistingText is true, completely replaces button text with the input
    /// Otherwise adds the list content to existing button texts
    /// Adds a period when appending to just a number (e.g., "1" + "Apple" becomes "1. Apple")
    private func processListInput() {
        // Split the input text by newlines
        let lines = listInputText.components(separatedBy: .newlines)
        
        // Apply each non-empty line to the corresponding button text field
        for (buttonIndex, line) in lines.enumerated() {
            if buttonIndex < viewModel.newButtonText.count {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                if modifyExistingText {
                    // In modify mode, completely replace the existing text
                    viewModel.newButtonText[buttonIndex] = trimmedLine
                } else if !trimmedLine.isEmpty {
                    // In append mode, only process non-empty lines
                    let currentText = viewModel.newButtonText[buttonIndex].trimmingCharacters(in: .whitespaces)
                    
                    if currentText.isEmpty {
                        // If button text is empty, just set the new text
                        viewModel.newButtonText[buttonIndex] = trimmedLine
                    } else {
                        // If the current text is just a number (like "1"), add a period before appending
                        if Int(currentText) != nil {
                            viewModel.newButtonText[buttonIndex] = "\(currentText). \(trimmedLine)"
                        } else if currentText.range(of: "^\\d+[.\\-):] ", options: .regularExpression) != nil {
                            // If there's already a numbered prefix, just append the new text
                            viewModel.newButtonText[buttonIndex] = "\(currentText) \(trimmedLine)"
                        } else {
                            // Regular text, append with a simple space
                            viewModel.newButtonText[buttonIndex] = "\(currentText) \(trimmedLine)"
                        }
                    }
                }
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
