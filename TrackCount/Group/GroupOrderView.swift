//
//  GroupOrderView.swift
//  TrackCount
//
//  Contains a view of the group in a re-orderable list
//

import SwiftUI
import SwiftData

struct GroupOrderView: View {
    @StateObject private var viewModel = GroupViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var validationError: [String] = []

    var body: some View {
        NavigationStack {
            List {
                if savedGroups.isEmpty {
                    Text("Create a group first to get started")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .transition(.opacity)
                } else {
                    // Display validation error if any
                    if !validationError.isEmpty {
                        Text(viewModel.validationError.joined(separator: ", "))
                            .foregroundStyle(.red)
                            .listRowSeparator(.hidden)
                            .padding()
                    }
                    
                    ForEach(savedGroups) { group in
                        HStack {
                            Image(systemName: "line.horizontal.3")
                                .foregroundStyle(.gray)
                            if !group.groupSymbol.isEmpty {
                                Image(systemName: group.groupSymbol)
                            }
                            if !group.groupTitle.isEmpty {
                                Text(group.groupTitle)
                                    .foregroundStyle(Color(.label))
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeGroup(group, with: context)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveGroup)
                    .transition(.slide)
                    
                    if !savedGroups.isEmpty {
                        Text("Drag a group to reorder, and swipe to delete")
                            .font(.footnote)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 1), value: savedGroups)
            .navigationTitle("Group Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            validationError.removeAll()
        }
    }
    
    /// A function invoked at a list's onMove that handles the movement of the groups in the list.
    /// Copies the groups and stores them to a modifiable variable.
    /// Updates the groups' index to reflect the new order.
    private func moveGroup(from source: IndexSet, to destination: Int) {
        // Extract the cards in a mutable array
        var mutableGroups = savedGroups.sorted(by: { $0.index < $1.index })
        
        // Perform the move in the mutable array
        mutableGroups.move(fromOffsets: source, toOffset: destination)
        
        // Update the index of the card to reflect the new order
        for index in mutableGroups.indices {
            mutableGroups[index].index = index
        }
        
        // Save the changes back to the context
        do {
            for groups in mutableGroups {
                if let selectedGroup = savedGroups.first(where: { $0.uuid == groups.uuid }) {
                    selectedGroup.index = groups.index // Update the ID in the context
                }
            }
            try context.save() // Persist the changes
        } catch {
            validationError.append("Failed to save updated order: \(error.localizedDescription)")
        }
    }
}

#Preview {
    GroupOrderView()
        .modelContainer(for: DMCardGroup.self)
}
