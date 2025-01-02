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
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isPresentingGroupForm: Bool = false
    @State var selectedGroup: DMCardGroup?
    @State var isEditing: EditMode = .inactive
    @State var animateGradient: Bool = false
    @State var isShowingDialog = false
    var viewBehaviour: Behaviour
    var gradientColors: [Color] {
        colorScheme == .light ? [.blue, .white] : [.white, .black]
    }
    let columnLayout: [GridItem] = [
        GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        /// Variable that stores black in light mode and white in dark mode
        /// Used for items with non-white primary light mode colors (i.e. buttons)
        let primaryColors: Color = colorScheme == .light ? Color.black : Color.white
        let backgroundGradient = RadialGradient(colors: gradientColors, center: .center, startRadius: animateGradient ? 15 : 25, endRadius: animateGradient ? 100 : 90)
        let onDragUpdate: (DragGesture.Value) -> Void
        let onDragEnd: () -> Void
        
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columnLayout, spacing: 16) {
                    ForEach(savedGroups) { group in
                        
                        let groupCardView = GroupCardView(
                            group: group,
                            backgroundGradient: backgroundGradient,
                            primaryColors: primaryColors,
                            selectedGroup: $selectedGroup,
                            animateGradient: $animateGradient,
                            isShowingDialog: $isShowingDialog
                        )
                        
                        NavigationLink(destination: destinationView(for: group)) {
                            groupCardView
                                .jiggle(amount: 2, isEnabled: isEditing == .active)
                                .frame(height: 200)
                                .contextMenu {
                                    Button("Share Group", systemImage: "square.and.arrow.up") {
                                        print("Sharing")
                                    }
                                    Button("Delete Group", systemImage: "trash", role: .destructive) {
                                        selectedGroup = group
                                        isShowingDialog = true
                                    }
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
                        ToolbarItem(placement: .navigationBarLeading) {
                            EditButton()
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { isPresentingGroupForm.toggle() }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                .environment(\.editMode, $isEditing)
                .sheet(isPresented: $isPresentingGroupForm) {
                    GroupFormView()
                        .presentationDetents([.fraction(0.45)])
                }
                .alert(isPresented: $isShowingDialog) {
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
                            isShowingDialog = false
                        }
                    )
                }
            }
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10) {
                isEditing = .active
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
