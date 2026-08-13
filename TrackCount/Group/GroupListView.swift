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
    
    // Grid Sizing
    let minGridWidth: CGFloat = 110
    let maxGridColumns: Int = 8
    let gridSpacing: CGFloat = 10
    
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
                            (
                                Text("Create a new group by tapping the ")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                +
                                Text(Image(systemName: "plus.rectangle.portrait"))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                +
                                Text(" in the top-right toolbar")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            )
                            .padding()
                        }
                        
                        if #available(anyAppleOS 27.0, *) {
                            LazyVGrid(columns: columns(for: geometry.size.width), spacing: gridSpacing) {
                                ForEach(filteredGroups) { group in
                                    groupCard(group)
                                }
                                .reorderable()
                            }
                            .reorderContainer(for: DMCardGroup.self) { difference in
                                applyReorderDifference(difference)
                            }
                            .padding()
                            .animation(.easeInOut(duration: 0.3), value: savedGroups.map { $0.index })
                        } else {
                            LazyVGrid(columns: columns(for: geometry.size.width), spacing: gridSpacing) {
                                ForEach(filteredGroups) { group in
                                    groupCard(group)
                                }
                            }
                            .padding()
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
                    .presentationDetents([.fraction(0.4)])
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
        // Compute how many columns fit, but never exceed maxColumns
        let count = max(1, min(maxGridColumns, Int(totalWidth / (minGridWidth + gridSpacing))))
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: count)
    }
    
    private func groupCard(_ group: DMCardGroup) -> some View {
        ZStack {
            Group {
                if #available(iOS 18.0, *) {
                    NavigationLink(
                        destination: TrackView(selectedGroup: group)
                            .navigationTransition(.zoom(sourceID: group.id, in: namespace))
                    ) {
                        GroupCardView(group: group)
                            .frame(height: 200)
                            .matchedTransitionSource(id: group.id, in: namespace)
                    }
                } else {
                    NavigationLink(destination: TrackView(selectedGroup: group)) {
                        GroupCardView(group: group)
                            .frame(height: 200)
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
