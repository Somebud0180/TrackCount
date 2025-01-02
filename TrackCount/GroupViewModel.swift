//
//  GroupViewModel.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 1/2/25.
//

import Foundation
import SwiftData

class GroupViewModel: ObservableObject {
    // Set variable defaults
    @Published var selectedGroup: DMCardGroup? = nil
    @Published var validationError: [String] = []
    @Published var newGroupIndex: Int = 0
    @Published var newGroupSymbol: String = ""
    @Published var newGroupTitle: String = ""
    
    /// Initializes the selectedGroup for editing
    /// - Parameter selectedGroup: (optional) accepts DMGroupCard entities, edits the entity that is passed over
    init(selectedGroup: DMCardGroup? = nil) {
        self.selectedGroup = selectedGroup
    }
    
    /// A function that fetches the existing group details for editing
    func fetchGroup() {
        print("Initializing edit group: \(selectedGroup?.groupTitle ?? "No Group Selected")")
        guard let selectedGroup else { return }
        self.newGroupTitle = selectedGroup.groupTitle
        self.newGroupSymbol = selectedGroup.groupSymbol
    }
    
    /// A function that resets all temporary variables back to defaull
    func resetFields() {
        selectedGroup = nil
        newGroupTitle = ""
        newGroupSymbol = ""
    }
    
    /// A function that checks the group's contents for any issues.
    /// Ensures atleast either one of the two variables (newGroupTitle and newGroupSymbol) is filled.
    /// Appends errors to validationError.
    func validateGroup() {
        validationError.removeAll()
        let titleIsEmpty = newGroupTitle.isEmpty
        let symbolIsEmpty = newGroupSymbol.isEmpty
        
        if titleIsEmpty && symbolIsEmpty {
            validationError.append("Group title cannot be empty without a symbol or vice versa")
        }
    }
    
    /// A function that stores the temporary variables to a group and saves it to the data model entity.
    /// Used to save the set variables into the group.
    /// Also checks the card contents and throws errors, if any, to validationError.
    /// Also provides the group's index and uuid on save.
    func addGroup(with context: ModelContext) {
        // Validate entry
        validateGroup()
        
        var savedGroups: [DMCardGroup] = []
        
        do {
            savedGroups = try context.fetch(FetchDescriptor<DMCardGroup>())
        } catch {
            print("Failed to fetch DMCardGroup: \(error)")
        }
        
        guard validationError.isEmpty else {
            return
        }
        
        if savedGroups.count == 0 {
            newGroupIndex = 0
        } else {
            newGroupIndex = savedGroups.count + 1
        }
        
        if selectedGroup != nil {
            // Update the existing group
            selectedGroup?.groupTitle = newGroupTitle
            selectedGroup?.groupSymbol = newGroupSymbol
        } else {
            // Create a new group
            let newGroup = DMCardGroup(uuid: UUID(),
                                       index: newGroupIndex,
                                       groupTitle: newGroupTitle,
                                       groupSymbol: newGroupSymbol)
            
            context.insert(newGroup)
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            validationError.append("Failed to save the group: \(error.localizedDescription)")
        }
        
        resetFields()
    }
}
