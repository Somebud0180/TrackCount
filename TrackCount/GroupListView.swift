//
//  GroupListView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

/// A view containing that lists all saved groups and provides access to editing the group's cards
struct GroupListView: View {
    /// Represents the behavior setting for the group list.
    enum Behaviour {
        case edit // Allows creating groups, NavigationLink directs to editing the group's cards
        case view // NavigationLink directs to viewing the group's cards
    }
    
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: GroupViewModel
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var animateGradient: Bool = false
    @State private var selectedGroup: DMCardGroup?
    @State var viewBehaviour: Behaviour
    
    let columnLayout: [GridItem] = [
        GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)
    ]
    
    init(viewBehaviour: Behaviour) {
        _viewModel = StateObject(wrappedValue: GroupViewModel())
        self.viewBehaviour = viewBehaviour
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columnLayout, spacing: 16) {
                    ForEach(savedGroups) { group in
                        
                        let groupCardView = GroupCardView(
                            animateGradient: $animateGradient,
                            group: group
                        )
                        
                        NavigationLink(destination: destinationView(for: group)) {
                            groupCardView
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
                            Button(action: { isPresentingGroupForm.toggle() }) {
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
                                removeGroup(group)
                                selectedGroup = nil
                            }
                        },
                        secondaryButton: .cancel {
                            selectedGroup = nil
                            isPresentingDeleteDialog = false
                        }
                    )
                }
            }
        }
    }
    
    /// Computed property for alert title
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
    
    /// A function that deletes the accepted group from storage
    private func removeGroup(_ group: DMCardGroup) {
        do {
            // Remove the group from the context
            context.delete(group)
            
            // Save the context after deletion
            try context.save()
            
            // Update the IDs of remaining cards to fill the gap
            var mutableGroups = savedGroups.sorted(by: { $0.index < $1.index })
            mutableGroups.removeAll { $0.uuid == group.uuid }
            
            // Reassign IDs to remaining cards
            for index in mutableGroups.indices {
                mutableGroups[index].index = index
            }
            
            // Save the changes back to the context
            try context.save()
            print("Group removed, ID freed, and remaining cards updated.")
        } catch {
            print("Failed to remove group and update IDs: \(error.localizedDescription)")
        }
    }

    /// A function that contains the buttons used in the context menu for the cards
    private func contextMenu(for group: DMCardGroup) -> some View {
        Group {
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
    
    private func shareGroup(_ group: DMCardGroup) {
        do {
            // Sanitize filename
            let sanitizedTitle = group.groupTitle
                .components(separatedBy: .init(charactersIn: "/\\?%*|\"<>"))
                .joined()
                .trimmingCharacters(in: .whitespaces)
            
            let fileName = sanitizedTitle.isEmpty ? "shared_group.trackcount" : "\(sanitizedTitle).trackcount"
            
            // Create temporary URL with unique identifier
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent(fileName)
            
            // Ensure directory exists
            try FileManager.default.createDirectory(
                at: tempURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            // Write data
            let shareData = try group.encodeForSharing()
            try shareData.write(to: tempURL, options: .atomic)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            // Cleanup after sharing
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            // Present sharing UI
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to share group: \(error)")
        }
    }
    
    /// A function that determines the destination based on the viewBehaviour
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
}
