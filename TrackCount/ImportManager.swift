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
    @Published var previewGroup: DMCardGroup?
    @Published var error: String?
    private var hasSecurityAccess = false
    
    /// Handles the URL on import and initializes shared groups for import.
    func handleImport(_ url: URL, with context: ModelContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reset()
            
            self.hasSecurityAccess = url.startAccessingSecurityScopedResource()
            guard self.hasSecurityAccess else { return }
            
            self.currentFileURL = url
            self.loadPreview(with: context)
        }
    }
    
    /// Loads the preview of the shared group and shows the alert.
    private func loadPreview(with context: ModelContext) {
        guard let url = currentFileURL else { return }
        
        do {
            let data = try Data(contentsOf: url)
            previewGroup = try DMCardGroup.decodeFromShared(data, context: context)
            showImportAlert = true
        } catch {
            self.error = "Preview failed: \(error.localizedDescription)"
        }
    }
    
    /// Confirms the import of the shared group.
    func confirmImport(with context: ModelContext) {
        guard let previewGroup = previewGroup else { return }
        
        do {
            let descriptor = FetchDescriptor<DMCardGroup>()
            let existingGroups = try context.fetch(descriptor)
            previewGroup.index = existingGroups.count
            
            context.insert(previewGroup)
            try context.save()
            reset()
        } catch {
            self.error = "Import failed: \(error.localizedDescription)"
        }
    }
    
    /// Resets the import variables.
    func reset() {
        if hasSecurityAccess {
            currentFileURL?.stopAccessingSecurityScopedResource()
            hasSecurityAccess = false
        }
        currentFileURL = nil
        previewGroup = nil
        showImportAlert = false
        error = nil
    }
}
