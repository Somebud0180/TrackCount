//
//  GroupViewModel.swift
//  TrackCount
//
//  Contains most of the logic related to groups
//

import Foundation
import SwiftData

class GroupViewModel: ObservableObject {
    // Set variable defaults
    @Published var importManager = ImportManager()
    @Published var selectedGroup: DMCardGroup?
    @Published var validationError: [String] = []
    @Published var warnError: [String] = []
    @Published var newGroupIndex: Int = 0
    @Published var newGroupSymbol: String = ""
    @Published var newGroupTitle: String = ""
    
    // Set limits
    let titleCharacterLimit = 32
    
    /// Initializes the `selectedGroup` for editing.
    /// - Parameter selectedGroup: (optional) accepts `DMGroupCard` entities, edits the entity that is passed over.
    init(selectedGroup: DMCardGroup? = nil) {
        self.selectedGroup = selectedGroup
    }
    
    /// A function that fetches the existing group details for editing.
    func fetchGroup() {
        guard let selectedGroup else { return }
        self.newGroupTitle = selectedGroup.groupTitle ?? ""
        self.newGroupSymbol = selectedGroup.groupSymbol ?? ""
    }
    
    /// A function that stores the temporary variables to a group and saves it to the data model entity.
    /// Used to save the set variables into the group.
    /// Also checks the card contents and throws errors, if any, to `validationError`.
    /// - Parameter context: The ModelContext to perform the save in.
    func saveGroup(with context: ModelContext) {
        // Validate entry
        validateForm()
        guard validationError.isEmpty else {
            return
        }
        
        // Fetch saved groups and get existing index
        var savedGroups: [DMCardGroup] = []
        
        do {
            savedGroups = try context.fetch(FetchDescriptor<DMCardGroup>())
        } catch {
            warnError.removeAll()
            warnError.append("Failed to fetch DMCardGroup: \(error)")
        }
        
        if savedGroups.count == 0 {
            newGroupIndex = 0
        } else {
            newGroupIndex = savedGroups.count + 1
        }
        
        
        do {
            if selectedGroup != nil {
                // Update the existing group
                selectedGroup?.groupTitle = newGroupTitle
                selectedGroup?.groupSymbol = newGroupSymbol
            } else {
                // Create a new group
                let newGroup = DMCardGroup(index: newGroupIndex,
                                           groupTitle: newGroupTitle,
                                           groupSymbol: newGroupSymbol)
                
                context.insert(newGroup)
            }
            
            // Save the context
            try context.save()
            resetFields()
        } catch {
            warnError.removeAll()
            warnError.append("Failed to save the group: \(error.localizedDescription)")
        }
        
    }
    
    /// Removes the selected group and updates the indices of remaining groups.
    /// - Parameters:
    ///   - context: The ModelContext to perform the removal in.
    ///   - group: The `DMCardGroup` to be removed.
    func removeGroup(_ group: DMCardGroup, with context: ModelContext) {
        do {
            // Delete the group
            context.delete(group)
            
            // Fetch all remaining groups
            let descriptor = FetchDescriptor<DMCardGroup>(sortBy: [SortDescriptor(\DMCardGroup.index)])
            let remainingGroups = try context.fetch(descriptor)
            
            // Update indices
            for (index, group) in remainingGroups.enumerated() {
                group.index = index
            }
            
            try context.save()
        } catch {
            warnError.removeAll()
            warnError.append("Failed to remove group and update IDs: \(error.localizedDescription)")
        }
    }
    
    /// A function that checks the group's contents for any issues.
    /// Ensures atleast either one of the two variables (`newGroupTitle` and `newGroupSymbol`) is filled.
    /// Appends errors to `validationError`.
    func validateForm() {
        validationError.removeAll()
        let trimmedTitle = newGroupTitle.trimmingCharacters(in: .whitespaces)
        
        let titleIsEmpty = trimmedTitle.isEmpty
        let symbolIsEmpty = newGroupSymbol.isEmpty
        
        if titleIsEmpty && symbolIsEmpty {
            validationError.append("TitleSymbolEmpty")
        }
    }
    
    /// A function that resets all temporary variables back to default values.
    func resetFields() {
        selectedGroup = nil
        newGroupTitle = ""
        newGroupSymbol = ""
    }
    
    /// Processes the group and packages it for export.
    /// - Parameter group: The group to be exported.
    /// - Returns: Returns the packaged group in a temporary URL.
    func shareGroup(_ group: DMCardGroup) throws -> URL {
        // Sanitize filename
        let sanitizedTitle = group.groupTitle ?? ""
            .components(separatedBy: .init(charactersIn: "/\\?%*|\"<>"))
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let fileName = sanitizedTitle.isEmpty ? "shared_group.trackcount" : "\(sanitizedTitle).trackcount"
        
        // Use top-level temp directory, not a nested folder
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Write data
        let shareData = try group.encodeForSharing()
        try shareData.write(to: tempURL, options: .atomic)
        
        return tempURL
    }
}
