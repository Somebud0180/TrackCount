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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var groupViewModel: GroupViewModel
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var cardViewModel: CardViewModel
    @StateObject private var debouncedStateManager: DebouncedCardStateManager
    @Namespace private var toggleButtonNamespace
    
    var selectedGroup: DMCardGroup
    @Query private var storedCards: [DMStoredCard]
    @State private var groupSheetHeight: CGFloat = .zero
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingCardFormView: Bool = false
    @State private var isPresentingCardListView: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var pressedStates: [String: Bool] = [:]
    
    let gridColumns = [GridItem(.adaptive(minimum: 450), spacing: 8)]
    let buttonColumns = [GridItem(.adaptive(minimum: 150), spacing: 8)]
    
    var pressedSize: CGFloat {
        if #available(iOS 26.0, *) {
            return 1.1
        } else {
            return 0.95
        }
    }
    
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
        
        NavigationStack {
            ScrollView {
                Group {
                    if storedCards.isEmpty {
                        Text("You have no cards yet")
                            .font(.title)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    } else {
                        // Define the grid layout
                        LazyVGrid(columns: gridColumns) {
                            // Display a message when there are no cards
                            // Iterate through the sorted cards and display each card
                            ForEach(storedCards, id: \.uuid) { card in
                                gridCard(card)
                            }
                        }
                    }
                }
                .padding(.vertical)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingCardFormView = true }) {
                        Label("Add Card", systemImage: "plus.circle")
                            .labelStyle(.iconOnly)
                    }
                    .legacyDarkTint()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingCardListView = true }) {
                        Label("Manage Cards", systemImage: "tablecells.badge.ellipsis")
                            .labelStyle(.iconOnly)
                    }
                    .legacyDarkTint()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Group", systemImage: "pencil") {
                            groupViewModel.fetchGroup()
                            isPresentingGroupForm = true
                        }
                        ShareLink(item: shareURL ?? URL(fileURLWithPath: "/")) {
                            Label("Share Group", systemImage: "square.and.arrow.up")
                        }.disabled(shareURL == nil)
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
                .presentationDetents([.fraction(0.45)])
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
        Group {
            ZStack {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer {
                        baseCard(card)
                    }
                } else {
                    baseCard(card)
                }
            }.padding()
        }
    }
    
    private func baseCard(_ card: DMStoredCard) -> some View {
        Group {
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
                }
            }.padding()
        }
    }
    
    /// Creates the counter card contents from the inputted card.
    private func counterCard(_ card: DMStoredCard) -> some View {
        VStack {
            buttonRow(
                card: card,
                operation: +,
                symbol: "plus",
                accessibilityLabel: "Increase counter",
                accessibilityHintPrefix: "Increase"
            )
            
            Spacer()
            
            // Current Count
            Text(String(card.count))
                .font(.largeTitle)
                .contentTransition(.numericText())
                .animation(.spring, value: card.count)
            
            Spacer()
            
            buttonRow(
                card: card,
                operation: -,
                symbol: "minus",
                accessibilityLabel: "Reduce counter",
                accessibilityHintPrefix: "Reduce"
            )
        }
        .frame(maxWidth: 450)
    }
    
    /// Creates a row of buttons for modifying the counter.
    @ViewBuilder private func buttonRow(
        card: DMStoredCard,
        operation: @escaping (Int, Int) -> Int,
        symbol: String,
        accessibilityLabel: String,
        accessibilityHintPrefix: String
    ) -> some View {
        HStack {
            if let modifiers = card.modifier?.map({ $0.modifier }) {
                ForEach(0..<modifiers.count, id: \.self) { index in
                    if modifiers[index] > 0 {
                        let willOverflow = operation(1, 1) == 2
                        ? card.count > Int.max - modifiers[index]
                        : card.count < Int.min + modifiers[index]
                        
                        Button(action: {
                            // Handle potential overflow and clamp the result within Int.min...Int.max
                            let newValue = operation(card.count, modifiers[index])
                            card.count = min(Int.max, max(Int.min, newValue))
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
                        .foregroundStyle(card.secondaryColor?.color ?? .white)
                        .adaptiveGlassButton(tintColor: willOverflow ? .gray : card.primaryColor?.color ?? .blue)
                        .accessibilityLabel(accessibilityLabel)
                        .accessibilityHint("\(accessibilityHintPrefix) \(card.title) by \(modifiers[index])")
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
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                pressedStates[buttonKey] = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedStates[buttonKey] = false
                }
            }
            
            if card.state?.indices.contains(id) == true {
                withAnimation {
                    // Toggle using debounced state manager with temporary state
                    debouncedStateManager.toggleState(of: card, at: id, with: context)
                }
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
            .foregroundStyle(isActive ? card.secondaryColor?.color ?? .white : .black)
        }
        .customConditionalButtonModifier(
            condition: isActive,
            tint: card.primaryColor?.color ?? .blue,
            shape: RoundedRectangle(cornerRadius: 12),
            externalPressed: isPressed
        )
    }
    
    /// Creates the timer card contents from the inputted card.
    private func timerCard(_ card: DMStoredCard) -> some View {
        Group {
            if card.type == .timer_custom && card.state?[0].state == false  {
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
                        card.state?[0] = CardState(state: true)
                        timerViewModel.startTimer(card)
                    }) {
                        Text("Start")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .adaptiveGlassButton(tintColor: card.primaryColor?.color ?? .blue)
                }
            } else if card.type == .timer && card.state?[0].state == false {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    ForEach(0..<card.count, id: \.self) { index in
                        Button(action: {
                            timerViewModel.selectedTimerIndex[card.uuid] = index
                            card.state?[0] = CardState(state: true)
                            timerViewModel.startTimer(card)
                        }) {
                            Circle()
                                .stroke(lineWidth: 10)
                                .opacity(0.3)
                                .foregroundColor(card.primaryColor?.color ?? .blue)
                                .overlay(
                                    Text((card.timer?[index].timerValue ?? 0).formatTime())
                                        .font(.system(.title2, weight: .bold))
                                        .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.3)
                                        .padding(.horizontal)
                                )
                                .frame(height: 100)
                                .padding(10)
                        }
                    }
                }
                
                Spacer()
            } else {
                timerViewModel.activeTimerView(card)
            }
        }
    }
    
    /// Computed property for alert title.
    private var alertTitle: Text {
        if (selectedGroup.groupTitle?.isEmpty == false) {
            return Text("Delete Group?")
        } else {
            return Text("Delete \(selectedGroup.groupTitle ?? "This Group")?")
        }
    }
}

#Preview {
    let exampleGroup = DMCardGroup(index: 0, groupTitle: "Test", groupSymbol: "", cards: [])
    let exampleCards: [DMStoredCard] = [
        DMStoredCard(index: 0, type: .counter, title: "Test Counter", count: 0, modifier: [1, 5, 10], primaryColor: .red, secondaryColor: .white, group: exampleGroup),
        DMStoredCard(index: 1, type: .toggle, title: "Test Toggle", count: 5, state: Array(repeating: true, count: 5), buttonText: Array(repeating: "Test", count: 5), symbol: "trophy.fill", primaryColor: .gray, secondaryColor: .yellow, group: exampleGroup),
        DMStoredCard(index: 2, type: .timer, title: "Test Timer", count: 4, state: [false], timer: [5, 15, 60, 3600], primaryColor: .blue, secondaryColor: .white, group: exampleGroup),
        DMStoredCard(index: 3, type: .timer_custom, title: "Test Timer (Custom)", count: 1, state: [false], timer: [0], primaryColor: .blue, secondaryColor: .white, group: exampleGroup),
    ]
    
    exampleGroup.cards = exampleCards
    
    return TrackView(selectedGroup: exampleGroup)
}
