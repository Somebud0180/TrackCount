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
    @StateObject private var viewModel = GroupViewModel()
    @Environment(\.modelContext) private var context
    
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isPresentingFilePicker = false
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingGroupOrder: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var selectedGroup: DMCardGroup?
    @State private var animateGradient: Bool = false
    
    private var columnLayout: [GridItem] {
        return [GridItem(.adaptive(minimum: 110, maximum: 400), spacing: 16)]
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
                                Text(Image(systemName: "ellipsis.circle"))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                +
                                Text(" in the top-right corner")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            )
                            .padding()
                        }
                        
                        LazyVGrid(columns: columns(for: geometry.size.width), spacing: 16) {
                            ForEach(savedGroups) { group in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 5)
                                    NavigationLink(destination: TrackView(selectedGroup: group)) {
                                        GroupCardView(group: group)
                                            .frame(height: 200)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityIdentifier(((group.groupTitle?.isEmpty != nil) ? group.groupSymbol : group.groupTitle) ?? "")
                                    .contextMenu {
                                        contextMenu(for: group)
                                    }
                                }
                            }
                        }
                        
                        .padding()
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Your Groups")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: { isPresentingGroupForm.toggle() }) {
                                    Label("Add Group", systemImage: "plus.circle")
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Button(action: { isPresentingFilePicker = true }) {
                                        Label("Import Group", systemImage: "square.and.arrow.down")
                                    }
                                    Button(action: { isPresentingGroupOrder.toggle() }) {
                                        Label("Reorder Groups", systemImage: "arrow.up.arrow.down")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .accessibilityIdentifier("Ellipsis Button")
                            }
                        }
                        .sheet(isPresented: $isPresentingGroupForm, onDismiss: {selectedGroup = nil}) {
                            GroupFormView(viewModel: viewModel)
                                .presentationDetents([.fraction(0.5)])
                                .onDisappear {
                                    viewModel.validationError.removeAll()
                                    viewModel.selectedGroup = nil
                                }
                        }
                        .sheet(isPresented: $isPresentingGroupOrder) {
                            GroupOrderView()
                                .environmentObject(viewModel)
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
                        .fileImporter(
                            isPresented: $isPresentingFilePicker,
                            allowedContentTypes: [.trackCountGroup],
                            allowsMultipleSelection: false
                        ) { result in
                            DispatchQueue.main.async {
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
                }
                .alert(importManager.previewGroup?.groupTitle?.isEmpty ?? true ? "Import Group?" : "Import Group \(importManager.previewGroup!.groupTitle ?? "")?", isPresented: $importManager.showImportAlert) {
                    VStack {
                        Button("Cancel", role: .cancel) {
                            importManager.reset()
                        }
                        Button("Import") {
                            importManager.confirmImport(with: context)
                        }
                    }
                } message: {
                    if let group = importManager.previewGroup, #available(iOS 18, *) {
                        Text("This group contains \(group.cards?.count ?? 1) \(group.cards?.count == 1 ? "card" : "cards").")
                    } else {
                        Text("Do you want to import this group?")
                    }
                }
            }
            .accentColor(colorScheme == .light ? .black : .primary)
        }
    }
    
    private func columns(for totalWidth: CGFloat) -> [GridItem] {
        let minWidth: CGFloat = 110
        let spacing: CGFloat = 16
        let maxColumns: Int = 8
        // Compute how many columns fit, but never exceed maxColumns
        let count = max(1, min(maxColumns, Int(totalWidth / (minWidth + spacing))))
        return Array(repeating: GridItem(.flexible()), count: count)
    }
    
    /// Computed property for alert title.
    private var alertTitle: Text {
        if let group = selectedGroup {
            if (group.groupTitle?.isEmpty != nil) {
                return Text("Delete Group?")
            } else {
                return Text("Delete \(group.groupTitle ?? "This Group")?")
            }
        }
        return Text("Delete Group?")
    }
    
    
    /// A function that handles the preparation of the groups for sharing.
    /// - Parameter group: The group to be shared, accepts type DMCardGroup.
    private func shareGroup(_ group: DMCardGroup) {
        do {
            let tempURL = try viewModel.shareGroup(group)
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            // Present sharing UI
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            viewModel.warnError.append(error.localizedDescription)
        }
    }
    
    /// A function that contains the buttons used in the context menu for the cards.
    private func contextMenu(for group: DMCardGroup) -> some View {
        Group {
            NavigationLink(destination: CardListView(selectedGroup: group)) {
                Label("Manage Cards", systemImage: "tablecells.badge.ellipsis")
                    .labelStyle(.titleAndIcon)
            }
            Button("Edit Group", systemImage: "pencil") {
                viewModel.selectedGroup = group
                viewModel.fetchGroup()
                isPresentingGroupForm.toggle()
            }
            Button("Share Group", systemImage: "square.and.arrow.up") {
                shareGroup(group)
            }
            Button("Delete Group", systemImage: "trash", role: .destructive) {
                selectedGroup = group
                isPresentingDeleteDialog = true
            }
        }
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: DMCardGroup.self)
        .environmentObject(ImportManager())
}
