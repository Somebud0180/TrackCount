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
    /// Represents the behavior setting for the group list.
    enum Behaviour {
        case edit // Allows creating groups, NavigationLink directs to editing the group's cards
        case view // NavigationLink directs to viewing the group's cards
    }
    
    @EnvironmentObject private var importManager: ImportManager
    @StateObject private var viewModel = GroupViewModel()
    @Environment(\.modelContext) private var context
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isShowingFilePicker = false
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var selectedGroup: DMCardGroup?
    @State var viewBehaviour: Behaviour
    
    let columnLayout: [GridItem] = [
        GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)
    ]
    
    init(viewBehaviour: Behaviour) {
        self.viewBehaviour = viewBehaviour
    }
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                // Display validation error if any
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError.joined(separator: ", "))
                        .foregroundStyle(.red)
                        .padding()
                }
                
                if savedGroups.isEmpty {
                    Text("Create a new group by tapping on the plus icon")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                
                LazyVGrid(columns: columnLayout, spacing: 16) {
                    ForEach(savedGroups) { group in
                        NavigationLink(destination: destinationView(for: group)) {
                            GroupCardView(group: group)
                                .frame(height: 200)
                                .contextMenu {
                                    contextMenu(for: group)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .navigationBarTitleDisplayMode(.large)
                .navigationTitle("Your Groups")
                .toolbar {
                    if viewBehaviour == .edit {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: { isPresentingGroupForm.toggle() }) {
                                    Label("New Group", systemImage: "plus.square")
                                }
                                
                                Button(action: { isShowingFilePicker = true }) {
                                    Label("Import Group", systemImage: "square.and.arrow.down")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $isPresentingGroupForm, onDismiss: {selectedGroup = nil}) {
                    GroupFormView(viewModel: viewModel)
                        .presentationDetents([.fraction(0.45)])
                }
                .alert(isPresented: $isPresentingDeleteDialog) {
                    Alert(
                        title: alertTitle,
                        message: Text("Are you sure you want to delete this group? This cannot be undone."),
                        primaryButton: .destructive(Text("Confirm")) {
                            if let group = selectedGroup {
                                viewModel.removeGroup(with: context, group: group)
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
                    isPresented: $isShowingFilePicker,
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
                            viewModel.validationError.append("File import failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .alert(importManager.previewGroup?.groupTitle.isEmpty ?? true ? "Import Group?" : "Import Group \"\(importManager.previewGroup!.groupTitle)\"?", isPresented: $importManager.showImportAlert) {
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
    }

    /// Computed property for alert title.
    private var alertTitle: Text {
        if let group = selectedGroup {
            if group.groupTitle.isEmpty {
                return Text("Delete Group?")
            } else {
                return Text("Delete \(group.groupTitle)?")
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
            viewModel.validationError.append(error.localizedDescription)
        }
    }
    
    /// A function that contains the buttons used in the context menu for the cards.
    private func contextMenu(for group: DMCardGroup) -> some View {
        Group {
            if viewBehaviour == .edit {
                Button("Edit Group", systemImage: "pencil") {
                    viewModel.selectedGroup = group
                    viewModel.fetchGroup()
                    isPresentingGroupForm.toggle()
                }
            }
            Button("Share Group", systemImage: "square.and.arrow.up") {
                shareGroup(group)
            }
            if viewBehaviour == .edit {
                Button("Delete Group", systemImage: "trash", role: .destructive) {
                    selectedGroup = group
                    isPresentingDeleteDialog = true
                }
            }
        }
    }
    
    /// A function that determines the destination based on the viewBehaviour.
    @ViewBuilder
    private func destinationView(for group: DMCardGroup) -> some View {
        if viewBehaviour == .edit {
            CardListView(selectedGroup: group)
        } else {
            TrackView(selectedGroup: group)
        }
    }
}

#Preview {
    GroupListView(viewBehaviour: .edit)
        .modelContainer(for: DMCardGroup.self)
        .environmentObject(ImportManager())
}
