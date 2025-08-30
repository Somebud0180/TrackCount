//
//  ImportManager.swift
//  TrackCount
//
//  Handles the URLs on import and initializes shared groups for import.
//

import SwiftUI
import SwiftData

class ImportManager: ObservableObject {
    @Published var showImportAlert = false
    @Published var currentFileURL: URL?
    @Published var previewGroup: PreviewCardGroup?
    @Published var error: String?
    private var hasSecurityAccess = false
    
    /// Handles the URL on import and initializes shared groups for import.
    func handleImport(_ url: URL, with context: ModelContext) {
        // Reset any previous state first
        reset()
        
        // Start accessing security scoped resource immediately
        hasSecurityAccess = url.startAccessingSecurityScopedResource()
        guard hasSecurityAccess else {
            error = "Failed to access security scoped resource"
            return
        }
        
        currentFileURL = url
        
        // For iOS 17.0 compatibility, perform the entire operation on the main actor
        Task { @MainActor in
            do {
                // Load data and create preview model (no SwiftData context needed)
                let data = try Data(contentsOf: url)
                let previewGroup = try DMCardGroup.createPreviewFromShared(data)
                
                // Set the preview group and show alert
                self.previewGroup = previewGroup
                self.showImportAlert = true
            } catch {
                self.error = "Preview failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Confirms the import of the shared group.
    func confirmImport(with context: ModelContext) {
        guard let previewGroup = previewGroup else { return }
        
        do {
            let descriptor = FetchDescriptor<DMCardGroup>()
            let existingGroups = try context.fetch(descriptor)
            
            // Convert preview to SwiftData model and insert properly
            let swiftDataGroup = try previewGroup.toSwiftDataModel(context: context)
            swiftDataGroup.index = existingGroups.count
            
            try context.save()
            reset()
        } catch {
            self.error = "Import failed: \(error.localizedDescription)"
        }
    }
    
    /// Resets the import variables.
    func reset() {
        if hasSecurityAccess, let url = currentFileURL {
            url.stopAccessingSecurityScopedResource()
            hasSecurityAccess = false
        }
        currentFileURL = nil
        previewGroup = nil
        showImportAlert = false
        error = nil
    }
}
