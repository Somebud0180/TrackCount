//
//  GroupListView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// A view containing that lists all saved groups and provides access to editing the group's cards.
struct GroupListView: View {
    @EnvironmentObject private var importManager: ImportManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = GroupViewModel()
    
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isPresentingFilePicker = false
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingGroupOrder: Bool = false
    @State private var isPresentingCardListView: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var selectedGroup: DMCardGroup?
    @State private var cardFormGroup: DMCardGroup?
    @State private var animateGradient: Bool = false
    @State private var searchText: String = ""
    @Namespace private var namespace
    
    // Grid Sizing & Aspect Ratio
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
    }
    
    private func isRegularLayout(for totalWidth: CGFloat) -> Bool {
        isIPad && totalWidth >= 500
    }
    
    private func minGridWidth(for totalWidth: CGFloat) -> CGFloat {
        isRegularLayout(for: totalWidth) ? 140 : 100
    }
    
    private func gridSpacing(for totalWidth: CGFloat) -> CGFloat {
        isRegularLayout(for: totalWidth) ? 14 : 10
    }
    
    let maxGridColumns: Int = 10
    let horizontalPadding: CGFloat = 16
    
    private var filteredGroups: [DMCardGroup] {
        if searchText.isEmpty {
            return savedGroups
        } else {
            return savedGroups.filter { group in
                (group.groupTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (preprocess(group.groupSymbol ?? "").localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [primaryThemeColor.color.opacity(0.8), Color.clear]),
            startPoint: .top,
            endPoint: .bottom
        )
        .hueRotation(.degrees(animateGradient ? 30 : 0))
        .task {
            if isGradientAnimated {
                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                    animateGradient.toggle()
                }
            }
        }
        .frame(height: 250)
        .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                backgroundGradient
                
                GeometryReader { geometry in
                    ScrollView {
                        // Display logic error if any
                        if !viewModel.warnError.isEmpty {
                            Text(viewModel.warnError.joined(separator: ", "))
                                .foregroundStyle(.red)
                                .padding()
                        }
                        
                        if savedGroups.isEmpty {
                            VStack(spacing: 8) {
                                (
                                    Text("Create a new group by tapping the ")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    +
                                    Text(Image(systemName: "plus.rectangle.portrait"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    +
                                    Text(" in the top-right toolbar")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                )
                                .multilineTextAlignment(.center)
                                .padding()
                            }
                            .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                        }
                        
                        let height = cardHeight(for: geometry.size.width)
                        let spacing = gridSpacing(for: geometry.size.width)
                        
                        if #available(anyAppleOS 27.0, *) {
                            LazyVGrid(columns: columns(for: geometry.size.width), spacing: spacing) {
                                ForEach(filteredGroups) { group in
                                    groupCard(group, cardHeight: height)
                                }
                                .reorderable()
                            }
                            .reorderContainer(for: DMCardGroup.self) { difference in
                                applyReorderDifference(difference)
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical)
                            .animation(.easeInOut(duration: 0.3), value: savedGroups.map { $0.index })
                        } else {
                            LazyVGrid(columns: columns(for: geometry.size.width), spacing: spacing) {
                                ForEach(filteredGroups) { group in
                                    groupCard(group, cardHeight: height)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical)
                            .animation(.easeInOut(duration: 0.3), value: savedGroups.map { $0.index })
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search groups")
            .accentColor(colorScheme == .light ? .black : .primary)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Your Groups")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingGroupForm = true }) {
                        Label("Add Group", systemImage: "plus.rectangle.portrait")
                    }
                    .legacyDarkTint()
                    
                    Menu {
                        Button(action: { isPresentingFilePicker = true }) {
                            Label("Import Group", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { isPresentingGroupOrder = true }) {
                            Label("Reorder Groups", systemImage: "arrow.up.arrow.down")
                        }
                        
                        NavigationLink(
                            destination: { SettingsView() },
                            label: { Label("Settings", systemImage: "gearshape") }
                        )
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .legacyDarkTint()
                    .accessibilityIdentifier("More Options")
                }
            }
            .sheet(isPresented: $isPresentingGroupForm, onDismiss: {selectedGroup = nil}) {
                GroupFormView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.35), .medium])
                    .onDisappear {
                        viewModel.validationError.removeAll()
                        viewModel.selectedGroup = nil
                    }
            }
            .sheet(isPresented: $isPresentingGroupOrder) {
                GroupOrderView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $isPresentingCardListView) {
                if let group = cardFormGroup {
                    CardListView(selectedGroup: group)
                        .presentationDetents([.medium, .large])
                        .onDisappear {
                            cardFormGroup = nil
                        }
                }
            }
            .onChange(of: cardFormGroup) {
                if cardFormGroup != nil {
                    isPresentingCardListView = true
                }
            }
            .alert(isPresented: $isPresentingDeleteDialog) {
                Alert(
                    title: alertTitle,
                    message: Text("Are you sure you want to delete this group? This cannot be undone."),
                    primaryButton: .destructive(Text("Confirm")) {
                        if let group = selectedGroup {
                            viewModel.removeGroup(group, with: context)
                            selectedGroup = nil
                        }
                    },
                    secondaryButton: .cancel {
                        selectedGroup = nil
                        isPresentingDeleteDialog = false
                    }
                )
            }
            .alert(importManager.previewGroup?.groupTitle.isEmpty ?? true ? "Import Group?" : "Import Group \(importManager.previewGroup?.groupTitle ?? "")?", isPresented: $importManager.showImportAlert) {
                VStack {
                    Button("Cancel", role: .cancel) {
                        importManager.reset()
                    }
                    Button("Import") {
                        importManager.confirmImport(with: context)
                    }
                }
            } message: {
                if let group = importManager.previewGroup {
                    Text("This group contains \(group.cards.count) \(group.cards.count == 1 ? "card" : "cards").")
                } else {
                    Text("Do you want to import this group?")
                }
            }
            .fileImporter(
                isPresented: $isPresentingFilePicker,
                allowedContentTypes: [.trackCountGroup],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importManager.handleImport(url, with: context)
                    }
                case .failure(let error):
                    viewModel.warnError.append("File import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func columns(for totalWidth: CGFloat) -> [GridItem] {
        let count = columnsCount(for: totalWidth)
        let spacing = gridSpacing(for: totalWidth)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
    
    private func columnsCount(for totalWidth: CGFloat) -> Int {
        let availableWidth = max(0, totalWidth - (horizontalPadding * 2))
        let minWidth = minGridWidth(for: totalWidth)
        let spacing = gridSpacing(for: totalWidth)
        return max(1, min(maxGridColumns, Int(availableWidth / (minWidth + spacing))))
    }
    
    private func cardHeight(for totalWidth: CGFloat) -> CGFloat {
        let availableWidth = max(0, totalWidth - (horizontalPadding * 2))
        let count = columnsCount(for: totalWidth)
        let spacing = gridSpacing(for: totalWidth)
        let columnWidth = max(0, (availableWidth - CGFloat(count - 1) * spacing) / CGFloat(count))
        
        let aspectRatio: CGFloat
        if isRegularLayout(for: totalWidth) {
            // For iPad: more square-ish card with vertical orientation preference (e.g. 0.85, height = width / 0.85)
            aspectRatio = 0.85
        } else {
            // For iPhone: slimmer/taller card with vertical orientation, strictly limited between 1:2 (0.5) and 9:16 (0.5625)
            let minRatio: CGFloat = 1.0 / 2.0  // 0.5 (1:2)
            let maxRatio: CGFloat = 9.0 / 16.0 // 0.5625 (9:16)
            let targetRatio: CGFloat = 9.0 / 16.0
            aspectRatio = min(max(targetRatio, minRatio), maxRatio)
        }
        
        return columnWidth / aspectRatio
    }
    
    private func groupCard(_ group: DMCardGroup, cardHeight: CGFloat) -> some View {
        ZStack {
            Group {
                if #available(iOS 18.0, *) {
                    NavigationLink(
                        destination: TrackView(selectedGroup: group)
                            .navigationTransition(.zoom(sourceID: group.id, in: namespace))
                    ) {
                        GroupCardView(group: group)
                            .frame(height: cardHeight)
                            .matchedTransitionSource(id: group.id, in: namespace)
                    }
                } else {
                    NavigationLink(destination: TrackView(selectedGroup: group)) {
                        GroupCardView(group: group)
                            .frame(height: cardHeight)
                    }
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                contextMenu(for: group)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(((group.groupTitle?.isEmpty == false) ? group.groupSymbol : group.groupTitle) ?? "")
        .accessibilityHint("Double-tap to open")
    }
    
    /// Computed property for alert title.
    private var alertTitle: Text {
        if let group = selectedGroup {
            if (group.groupTitle?.isEmpty ?? true) {
                return Text("Delete Group?")
            } else {
                return Text("Delete \(group.groupTitle ?? "This Group")?")
            }
        }
        return Text("Delete Group?")
    }
    
    /// A function that contains the buttons used in the context menu for the cards.
    private func contextMenu(for group: DMCardGroup) -> some View {
        // Safely get a share URL, disabling if unavailable
        let shareURL = try? viewModel.shareGroup(group)
        
        return Group {
            Button("Manage Cards", systemImage: "tablecells.badge.ellipsis") {
                cardFormGroup = group
            }
            Button("Edit Group", systemImage: "pencil") {
                viewModel.selectedGroup = group
                viewModel.fetchGroup()
                isPresentingGroupForm = true
            }
            ShareLink(item: shareURL ?? URL(fileURLWithPath: "/")) {
                Label("Share Group", systemImage: "square.and.arrow.up")
            }.disabled(shareURL == nil)
            Button("Delete Group", systemImage: "trash", role: .destructive) {
                selectedGroup = group
                isPresentingDeleteDialog = true
            }
        }
    }
    
    /// Applies a `ReorderDifference` produced by `reorderContainer` to update group indices.
    @available(anyAppleOS 27.0, *)
    private func applyReorderDifference<Destination>(_ difference: ReorderDifference<DMCardGroup.ID, Destination>) {
        // 1. Create a working copy sorted by index
        var mutableGroups = savedGroups.sorted { ($0.index ?? 0) < ($1.index ?? 0) }
        
        // 2. Locate elements referenced by difference.sources
        var movedGroups: [DMCardGroup] = []
        for sourceID in difference.sources {
            if let group = mutableGroups.first(where: { $0.id == sourceID }) {
                movedGroups.append(group)
            }
        }
        
        guard !movedGroups.isEmpty else { return }
        
        // 3. Remove moved elements from their original positions
        mutableGroups.removeAll { group in
            difference.sources.contains(group.id)
        }
        
        // 4. Insert moved elements at target destination
        switch difference.destination.position {
        case .before(let targetID):
            if let targetIndex = mutableGroups.firstIndex(where: { $0.id == targetID }) {
                mutableGroups.insert(contentsOf: movedGroups, at: targetIndex)
            } else {
                mutableGroups.append(contentsOf: movedGroups)
            }
        case .end:
            mutableGroups.append(contentsOf: movedGroups)
        @unknown default:
            mutableGroups.append(contentsOf: movedGroups)
        }
        
        // 5. Reassign indices and persist
        withAnimation {
            for (newIndex, group) in mutableGroups.enumerated() {
                group.index = newIndex
            }
            
            do {
                try context.save()
            } catch {
                viewModel.warnError.append("Failed to save reordered groups: \(error.localizedDescription)")
            }
        }
    }
    
    /// A helper function to preprocess the symbol names for better searchability.
    private func preprocess(_ symbol: String) -> String {
        symbol
            .replacingOccurrences(of: ".fill", with: "") // Remove ".fill"
            .replacingOccurrences(of: ".", with: " ") // Replace "." with a space
            .lowercased()
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: DMCardGroup.self)
        .environmentObject(ImportManager())
}
