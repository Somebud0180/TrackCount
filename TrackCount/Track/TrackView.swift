//
//  TrackView.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct TrackView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var groupViewModel: GroupViewModel
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var cardViewModel: CardViewModel
    @StateObject private var debouncedStateManager: DebouncedCardStateManager
    @StateObject private var noteEditorController = NoteTextEditorController()
    @Namespace private var toggleButtonNamespace
    
    var selectedGroup: DMCardGroup
    @Query private var storedCards: [DMStoredCard]
    @State private var groupSheetHeight: CGFloat = .zero
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingCardFormView: Bool = false
    @State private var isPresentingCardListView: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var pressedStates: [String: Bool] = [:]
    
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    @State private var currentMatchIndex: Int = 0
    @FocusState private var focusSearch
    
    @AppStorage("trackGridSize") var gridSizeOption: Int = DefaultSettings.trackGridSize  // 0 = compact, 1 = default, 2 = relaxed
    @State private var gridSize: [CGFloat] = [320, 400, 450]
    
    let buttonColumns = [GridItem(.adaptive(minimum: 150), spacing: 8)]
    
    init(selectedGroup: DMCardGroup) {
        _groupViewModel = StateObject(wrappedValue: GroupViewModel(selectedGroup: selectedGroup))
        _timerViewModel = StateObject(wrappedValue: TimerViewModel())
        _cardViewModel = StateObject(wrappedValue: CardViewModel(selectedGroup: selectedGroup))
        _debouncedStateManager = StateObject(wrappedValue: DebouncedCardStateManager())
        
        self.selectedGroup = selectedGroup
        let groupID = selectedGroup.uuid
        _storedCards = Query(filter: #Predicate<DMStoredCard> { $0.group?.uuid == groupID }, sort: \DMStoredCard.index, order: .forward)
    }
    
    var body: some View {
        // Safely get a share URL for the group
        let shareURL = try? groupViewModel.shareGroup(selectedGroup)
        
        // Define grid layout with adaptive columns
        let gridColumns = [GridItem(.adaptive(minimum: gridSize[gridSizeOption]), spacing: 16)]
        
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Group {
                        if storedCards.isEmpty {
                            Text("You have no cards yet")
                                .font(.title)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            // Define the grid layout
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                // Display a message when there are no cards
                                // Iterate through the sorted cards and display each card
                                ForEach(storedCards, id: \.uuid) { card in
                                    gridCard(card)
                                        .id(card.uuid)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    if isSearchActive {
                        if #available(anyAppleOS 26.0, *) {
                            GlassEffectContainer {
                                searchBar(proxy: proxy)
                            }
                        } else {
                            searchBar(proxy: proxy)
                                .background(.bar)
                        }
                    } else if noteEditorController.isEditing {
                        NoteFormattingToolbar(editor: noteEditorController)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: noteEditorController.isEditing)
                .onChange(of: noteEditorController.editingCardUUID) {
                    if let uuid = noteEditorController.editingCardUUID {
                        // Delay slightly to let the scroll view resize for the keyboard
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(uuid, anchor: .center)
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    if let uuid = noteEditorController.editingCardUUID {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(uuid, anchor: .center)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitleViewBuilder {
                if (selectedGroup.groupTitle?.isEmpty != nil) {
                    Image(systemName: selectedGroup.groupSymbol ?? "")
                } else {
                    Text(selectedGroup.groupTitle ?? "")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { 
                        withAnimation {
                            isSearchActive.toggle()
                            focusSearch = isSearchActive
                            if !isSearchActive {
                                searchText = ""
                                currentMatchIndex = 0
                            }
                        }
                    }) {
                        Label("Search", systemImage: "magnifyingglass")
                            .labelStyle(.iconOnly)
                    }
                    .legacyDarkTint()
                    
                    Button(action: { isPresentingCardFormView = true }) {
                        Label("Add Card", systemImage: "plus.circle")
                            .labelStyle(.iconOnly)
                    }
                    .legacyDarkTint()
                    
                    Button(action: { isPresentingCardListView = true }) {
                        Label("Manage Cards", systemImage: "tablecells.badge.ellipsis")
                            .labelStyle(.iconOnly)
                    }
                    .legacyDarkTint()
                    
                    Menu {
                        Button("Edit Group", systemImage: "pencil") {
                            groupViewModel.fetchGroup()
                            isPresentingGroupForm = true
                        }
                        ShareLink(item: shareURL ?? URL(fileURLWithPath: "/")) {
                            Label("Share Group", systemImage: "square.and.arrow.up")
                        }.disabled(shareURL == nil)
                        
                        Menu {
                            Button(action: { withAnimation { gridSizeOption = 0 }}) {
                                if gridSizeOption == 0 { Label("Compact", systemImage: "checkmark") } else {
                                    Text("Compact")
                                }
                            }
                            Button(action: { withAnimation { gridSizeOption = 1 }}) {
                                if gridSizeOption == 1 { Label("Medium", systemImage: "checkmark") } else {
                                    Text("Medium")
                                }
                            }
                            Button(action: { withAnimation { gridSizeOption = 2 }}) {
                                if gridSizeOption == 2 { Label("Large", systemImage: "checkmark") } else {
                                    Text("Large")
                                }
                            }
                        } label: {
                            Label("Grid Size", systemImage: "square.grid.2x2")
                        }
                        
                        Button("Delete Group", systemImage: "trash", role: .destructive) {
                            isPresentingDeleteDialog = true
                        }
                    } label: {
                        Label("Group Options", systemImage: "ellipsis.circle")
                    }
                    .legacyDarkTint()
                }
            }
        }
        .sheet(isPresented: $isPresentingGroupForm) {
            GroupFormView(viewModel: groupViewModel)
                .presentationDetents([.fraction(0.3)])
                .onDisappear {
                    groupViewModel.validationError.removeAll()
                    groupViewModel.selectedGroup = nil
                }
        }
        .sheet(isPresented: $isPresentingCardFormView, onDismiss: {
            cardViewModel.resetFields()
        }) {
            CardFormView(viewModel: cardViewModel)
                .presentationDetents([.fraction(0.6), .fraction(0.99)])
                .onDisappear {
                    cardViewModel.validationError.removeAll()
                }
        }
        .sheet(isPresented: $isPresentingCardListView) {
            CardListView(selectedGroup: selectedGroup)
                .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $isPresentingDeleteDialog) {
            Alert(
                title: alertTitle,
                message: Text("Are you sure you want to delete this group? This cannot be undone."),
                primaryButton: .destructive(Text("Confirm")) {
                    groupViewModel.removeGroup(selectedGroup, with: context)
                    dismiss()
                },
                secondaryButton: .cancel {
                    isPresentingDeleteDialog = false
                }
            )
        }
        .onAppear {
            // Set navigation state to indicate we're in TrackView
            GlobalTimerManager.shared.setNavigationState(isInTrackView: true, groupUUID: selectedGroup.uuid)
            
            // Cancel all pending timer notifications since user is actively viewing timers
            NotificationManager.shared.cancelAllPendingTimerNotifications()
            
            // Load any persisted timers for this group
            timerViewModel.loadPersistedTimers(for: selectedGroup)
        }
        .onDisappear {
            // Set navigation state to indicate we're leaving TrackView
            GlobalTimerManager.shared.setNavigationState(isInTrackView: false, groupUUID: nil)
            
            // Reschedule notifications for any active timers in this group
            NotificationManager.shared.rescheduleNotificationsForGroup(groupUUID: selectedGroup.uuid)
            
            // Apply any pending temporary changes immediately before leaving the view
            debouncedStateManager.applyAllTemporaryChanges(with: context)
            
            // Only cleanup audio and UI state, not the timer data
            timerViewModel.cleanupAudioOnly()
        }
    }
    
    /// Builds the inputted card into a visible card according to it's type.
    private func gridCard(_ card: DMStoredCard) -> some View {
        let isMatch = matchUUIDs.indices.contains(currentMatchIndex) && matchUUIDs[currentMatchIndex] == card.uuid
        return Group {
                if #available(anyAppleOS 26.0, *) {
                    GlassEffectContainer {
                        baseCard(card)
                            .overlay {
                                if isMatch {
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.blue, lineWidth: 2)
                                }
                            }
                    }
                } else {
                    baseCard(card)
                        .overlay {
                            if isMatch {
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue, lineWidth: 2)
                            }
                        }
                }
        }
    }
    
    private func baseCard(_ card: DMStoredCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .foregroundStyle(.thickMaterial)
                .shadow(radius: 5)
            
            VStack(alignment: .center, spacing: 10) {
                Text(card.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityHint("Counter Card")
                
                Spacer(minLength: 0)
                
                if card.type == .counter {
                    counterCard(card)
                } else if card.type == .toggle {
                    toggleCard(card)
                } else if card.type == .timer || card.type == .timer_custom {
                    timerCard(card)
                        .transition(.scale.combined(with: .opacity))
                } else if card.type == .note {
                    noteCard(card)
                }
            }.padding(12)
        }
    }
    
    /// Creates the counter card contents from the inputted card.
    private func counterCard(_ card: DMStoredCard) -> some View {
        VStack {
            Spacer()
            
            buttonRow(
                card: card,
                operation: +,
                symbol: "plus",
                accessibilityLabelPrefix: "Increase"
            )
            
            // Current Count
            Text(String(card.count))
                .font(.largeTitle)
                .padding(.vertical, 12)
                .contentTransition(.numericText())
                .animation(.spring, value: card.count)
            
            buttonRow(
                card: card,
                operation: -,
                symbol: "minus",
                accessibilityLabelPrefix: "Reduce"
            )
        }
        .frame(maxWidth: 450)
    }
    
    /// Creates a row of buttons for modifying the counter.
    @ViewBuilder private func buttonRow(
        card: DMStoredCard,
        operation: @escaping (Int, Int) -> Int,
        symbol: String,
        accessibilityLabelPrefix: String
    ) -> some View {
        HStack {
            if let modifiers = card.modifier?.map({ $0.modifier }) {
                ForEach(0..<modifiers.count, id: \.self) { index in
                    if modifiers[index] > 0 {
                        let buttonKey = "\(card.uuid)_mod_\(symbol)_\(index)"
                        let isPressed = pressedStates[buttonKey] ?? false
                        let willOverflow = operation(1, 1) == 2
                        ? card.count > Int.max - modifiers[index]
                        : card.count < Int.min + modifiers[index]
                        let tint = willOverflow ? .gray : card.primaryColor?.color ?? .blue
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                pressedStates[buttonKey] = true
                                let newValue = operation(card.count, modifiers[index])
                                card.count = min(Int.max, max(Int.min, newValue))
                            }
                            
                            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                                pressedStates[buttonKey] = false
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: symbol)
                                    .font(.body)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.xxxLarge)
                                    .minimumScaleFactor(0.5)
                                    .frame(height: 25)
                                if modifiers[index] != 1 {
                                    Text("\(modifiers[index])")
                                        .font(.title3)
                                        .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.xxxLarge)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 44)
                            .padding(6)
                        }
                        .disabled(willOverflow)
                        .foregroundStyle((card.secondaryColor?.color ?? .white).readableOn(tint, sensitivity: usesLiquidGlass ? 0.7 : 0.75))
                        .adaptiveGlassButton(interactive: !willOverflow, tintColor: tint, externalPressed: isPressed)
                        .accessibilityLabel("\(accessibilityLabelPrefix) \(card.title) by \(modifiers[index])")
                    }
                }
            }
        }
    }
    
    /// Creates the toggle card contents from the inputted card.
    private func toggleCard(_ card: DMStoredCard) -> some View {
        Group {
            LazyVGrid(columns: buttonColumns) {
                ForEach(0..<card.count, id: \.self) { index in
                    toggleButton(card, id: index)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    /// Creates buttons with data from the inputted card and index.
    private func toggleButton(_ card: DMStoredCard, id: Int) -> some View {
        let isActive = debouncedStateManager.getToggleState(for: card, buttonIndex: id)
        let buttonText = card.buttonText?[id].buttonText ?? ""
        let symbolName = card.symbol ?? "questionmark.circle"
        let buttonKey = "\(card.uuid)_\(id)"
        let isPressed = pressedStates[buttonKey] ?? false
        let tint = card.primaryColor?.color ?? .blue
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                pressedStates[buttonKey] = true
                
                if card.state?.indices.contains(id) == true {
                    // Toggle using debounced state manager with temporary state
                    debouncedStateManager.toggleState(of: card, at: id, with: context)
                }
            }
            
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                pressedStates[buttonKey] = false
            }
        }) {
            VStack {
                Spacer()
                if !buttonText.isEmpty {
                    HStack {
                        Text(buttonText)
                            .font(.body)
                            .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.accessibility1)
                            .minimumScaleFactor(0.3)
                            .lineLimit(2)
                        Image(systemName: symbolName)
                            .font(.footnote)
                            .dynamicTypeSize(DynamicTypeSize.xSmall...DynamicTypeSize.xxxLarge)
                            .minimumScaleFactor(0.2)
                    }
                } else {
                    VStack {
                        Image(systemName: symbolName)
                            .font(.body)
                            .minimumScaleFactor(0.2)
                    }
                }
                Spacer()
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: 20, maxHeight: .infinity)
            .foregroundStyle(isActive ? (card.secondaryColor?.color ?? .white).readableOn(tint, sensitivity: usesLiquidGlass ? 0.7 : 0.75) : .black)
        }
        .customConditionalButtonModifier(
            condition: isActive,
            tint: tint,
            shape: RoundedRectangle(cornerRadius: 12),
            externalPressed: isPressed
        )
        .scaleEffect(isActive ? 1.0 : 0.95)
    }
    
    /// Creates the timer card contents from the inputted card.
    private func timerCard(_ card: DMStoredCard) -> some View {
        let startButtonKey = "\(card.uuid)_start"
        let isStartButtonPressed = pressedStates[startButtonKey] ?? false
        let timerState = timerViewModel.timerStates[card.uuid] ?? .idle
        let tint = card.primaryColor?.color ?? .blue
        return Group {
            if card.type == .timer_custom && timerState == .idle  {
                VStack {
                    Text("Set Timer")
                        .font(.headline)
                    
                    Spacer()
                    
                    TimeWheelPickerView(
                        timerArray: Binding(
                            get: {
                                let seconds = card.timer?[0].timerValue ?? 0
                                let h = seconds / 3600
                                let m = (seconds % 3600) / 60
                                let s = seconds % 60
                                return [h, m, s]
                            },
                            set: { timerArray in
                                let totalSeconds = timerArray[0] * 3600 + timerArray[1] * 60 + timerArray[2]
                                card.timer?[0] = TimerValue(timerValue: totalSeconds)
                            }
                        )
                    )
                    .frame(height: 150)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            pressedStates[startButtonKey] = true
                            timerViewModel.startTimer(card)
                        }
                        
                        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                            pressedStates[startButtonKey] = false
                        }
                    }) {
                        Text("Start")
                            .foregroundStyle((card.secondaryColor?.color ?? .white).readableOn(tint, sensitivity: usesLiquidGlass ? 0.7 : 0.75))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .adaptiveGlassButton(tintColor: tint, externalPressed: isStartButtonPressed)
                }
            } else if card.type == .timer && timerState == .idle {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    ForEach(0..<card.count, id: \.self) { index in
                        if let timerValue = card.timer?[index].timerValue {
                            Button(action: {
                                timerViewModel.selectedTimerIndex[card.uuid] = index
                                timerViewModel.startTimer(card)
                            }) {
                                Circle()
                                    .stroke(lineWidth: 10)
                                    .opacity(0.3)
                                    .foregroundColor(card.primaryColor?.color ?? .blue)
                                    .overlay(
                                        Text(timerValue.formatTime())
                                            .font(.system(.title2, weight: .bold))
                                            .foregroundStyle((card.secondaryColor?.color ?? .white).readable(in: colorScheme))
                                            .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.3)
                                            .padding(.horizontal)
                                    )
                                    .frame(height: 100)
                                    .padding(10)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Timer Preset")
                            .accessibilityValue(accessibleTimeFormat(Double(timerValue)))
                            .accessibilityHint("Double-tap to start timer")
                        }
                    }
                }
                
                Spacer()
            } else {
                timerViewModel.activeTimerView(card)
            }
        }
    }
    
    private func noteCard(_ card: DMStoredCard) -> some View {
        let textColor = card.primaryColor?.color ?? .primary
        let backgroundColor = card.secondaryColor?.color ?? .secondary
        let lockState = card.state?[0].state ?? false
        
        return ZStack {
            RoundedRectangle(cornerRadius: 13)
                .foregroundStyle(backgroundColor)
                .opacity(0.9)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 2) {
                AttributedTextEditor(
                    noteData: noteDataBinding(for: card),
                    controller: noteEditorController,
                    textColor: UIColor(textColor.readableOn(backgroundColor)),
                    locked: lockState,
                    cardUUID: card.uuid,
                    bottomPadding: 52
                )
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .overlay(alignment: .bottomTrailing, content: {
                    Button(action: {
                        if lockState {
                            card.state?[0].state = false
                        } else {
                            card.state?[0].state = true
                        }
                    }, label: {
                        if #available(iOS 18.0, *) {
                            Image(systemName: lockState ? "lock.fill" : "lock.open.fill")
                                .imageScale(.medium)
                                .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                        } else {
                            Image(systemName: lockState ? "lock.fill" : "lock.open.fill")
                                .imageScale(.medium)
                        }
                    })
                    .foregroundStyle(textColor.readableOn(backgroundColor))
                    .frame(maxWidth: 44, maxHeight: 44)
                    .aspectRatio(1, contentMode: .fit)
                    .adaptiveGlassButton()
                })
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func noteDataBinding(for card: DMStoredCard) -> Binding<Data?> {
        Binding(
            get: { card.noteData },
            set: { card.noteData = $0 }
        )
    }
    
    /// Computed property for alert title.
    private var alertTitle: Text {
        return Text("Delete \(selectedGroup.groupTitle ?? "This Group")?")
    }
    
    private func searchBar(proxy: ScrollViewProxy) -> some View {
        let matches = matchUUIDs
        
        if #available(anyAppleOS 26.0, *) {
            return HStack {
                Button(action: {
                    withAnimation {
                        isSearchActive = false
                        searchText = ""
                        currentMatchIndex = 0
                    }
                }, label: {
                    Label("Done", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                })
                .foregroundStyle(.primary)
                .frame(minWidth: 24, minHeight: 24)
                .padding(12)
                .adaptiveGlassButton(tintStrength: 0)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cards...", text: $searchText)
                        .focused($focusSearch)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) {
                            currentMatchIndex = 0
                            if !matchUUIDs.isEmpty {
                                scrollToCurrentMatch(proxy: proxy)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Text("\(matches.isEmpty ? 0 : currentMatchIndex + 1) of \(matches.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            searchText = ""
                            currentMatchIndex = 0
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(minHeight: 24)
                .customRoundedGlass()
                
                HStack(spacing: 12) {
                    Button(action: { previousMatch(proxy: proxy) }) {
                        Image(systemName: "chevron.up")
                            .fontWeight(.medium)
                    }
                    .disabled(matches.isEmpty)
                    
                    Button(action: { nextMatch(proxy: proxy) }) {
                        Image(systemName: "chevron.down")
                            .fontWeight(.medium)
                    }
                    .disabled(matches.isEmpty)
                }
                .frame(minHeight: 24)
                .customRoundedGlass()
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
        } else {
            return HStack(spacing: 18) {
                Button(action: {
                    withAnimation {
                        isSearchActive = false
                        searchText = ""
                        currentMatchIndex = 0
                    }
                }, label: {
                    Label("Done", systemImage: "xmark")
                        .labelStyle(.titleOnly)
                        .font(.headline)
                })
                .foregroundStyle(.primary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cards...", text: $searchText)
                        .focused($focusSearch)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchText) {
                            currentMatchIndex = 0
                            if !matchUUIDs.isEmpty {
                                scrollToCurrentMatch(proxy: proxy)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Text("\(matches.isEmpty ? 0 : currentMatchIndex + 1) of \(matches.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            searchText = ""
                            currentMatchIndex = 0
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(Color(UIColor.systemGray4))
                )
                
                HStack(spacing: 12) {
                    Group {
                        Button(action: { previousMatch(proxy: proxy) }) {
                            Image(systemName: "chevron.up")
                        }
                        
                        Button(action: { nextMatch(proxy: proxy) }) {
                            Image(systemName: "chevron.down")
                        }
                    }
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .disabled(matches.isEmpty)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal)
        }
    }
    
    private var matchUUIDs: [UUID] {
        guard !searchText.isEmpty else { return [] }
        return storedCards.filter { $0.title.localizedCaseInsensitiveContains(searchText) }.map { $0.uuid }
    }
    
    private func nextMatch(proxy: ScrollViewProxy) {
        let matches = matchUUIDs
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matches.count
        scrollToCurrentMatch(proxy: proxy)
    }

    private func previousMatch(proxy: ScrollViewProxy) {
        let matches = matchUUIDs
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matches.count) % matches.count
        scrollToCurrentMatch(proxy: proxy)
    }

    private func scrollToCurrentMatch(proxy: ScrollViewProxy) {
        let matches = matchUUIDs
        guard !matches.isEmpty && currentMatchIndex < matches.count else { return }
        withAnimation {
            proxy.scrollTo(matches[currentMatchIndex], anchor: .center)
        }
    }
}
