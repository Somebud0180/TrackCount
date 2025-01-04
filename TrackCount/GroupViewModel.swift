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
    @Published var selectedGroup: DMCardGroup? = nil
    @Published var validationError: [String] = []
    @Published var newGroupIndex: Int = 0
    @Published var newGroupSymbol: String = ""
    @Published var newGroupTitle: String = ""
    
    /// Initializes the selectedGroup for editing.
    /// - Parameter selectedGroup: (optional) accepts DMGroupCard entities, edits the entity that is passed over.
    init(selectedGroup: DMCardGroup? = nil) {
        self.selectedGroup = selectedGroup
    }
    
    /// A function that fetches the existing group details for editing.
    func fetchGroup() {
        print("Initializing edit group: \(selectedGroup?.groupTitle ?? "No Group Selected")")
        guard let selectedGroup else { return }
        self.newGroupTitle = selectedGroup.groupTitle
        self.newGroupSymbol = selectedGroup.groupSymbol
    }
    
    /// A function that resets all temporary variables back to default values.
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
        let trimmedTitle = newGroupTitle.trimmingCharacters(in: .whitespaces)
        
        let titleIsEmpty = trimmedTitle.isEmpty
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
    
    /// Removes the selected group and updates the indices of remaining groups.
    /// - Parameters:
    ///   - context: The ModelContext to perform operations in.
    ///   - group: The DMCardGroup to be removed.
    func removeGroup(with context: ModelContext, group: DMCardGroup) {
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
            validationError.append("Failed to remove group and update IDs: \(error.localizedDescription)")
        }
    }
    
    /// Processes the group and packages it for export.
    /// - Parameter group: The group to be exported.
    /// - Returns: Returns the packaged group in a temporary URL.
    func shareGroup(_ group: DMCardGroup) throws -> URL {
        // Sanitize filename
        let sanitizedTitle = group.groupTitle
            .components(separatedBy: .init(charactersIn: "/\\?%*|\"<>"))
            .joined()
            .trimmingCharacters(in: .whitespaces)
        
        let fileName = sanitizedTitle.isEmpty ? "shared_group.trackcount" : "\(sanitizedTitle).trackcount"
        
        // Create temporary URL
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
        
        return tempURL
    }
    
    /// Handles the shared group and saves it to storage.
    /// - Parameter context: The context where the group will be stored.
    func importGroup(with context: ModelContext) {
        guard let previewGroup = importManager.previewGroup else { return }
        
        do {
            // Fetch existing groups to determine new index
            let descriptor = FetchDescriptor<DMCardGroup>()
            let existingGroups = try context.fetch(descriptor)
            
            // Set new index
            previewGroup.index = existingGroups.count
            
            // Insert group
            context.insert(previewGroup)
            try context.save()
            
            importManager.reset()
        } catch {
            validationError.append("Failed to import group: \(error.localizedDescription)")
        }
    }
}
