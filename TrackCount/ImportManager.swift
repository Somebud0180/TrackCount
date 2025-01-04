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
    private var hasSecurityAccess = false
    
    /// Handles the URL on import and initializes shared groups for import.
    func handleImport(_ url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reset()
            
            self.hasSecurityAccess = url.startAccessingSecurityScopedResource()
            guard self.hasSecurityAccess else { return }
            
            self.currentFileURL = url
            self.loadPreview()
        }
    }
    
    /// Loads the preview of the shared group and shows the alert.
    private func loadPreview() {
        guard let url = currentFileURL else { return }
        do {
            let data = try Data(contentsOf: url)
            let container = try ModelContainer(for: DMCardGroup.self)
            let context = ModelContext(container)
            previewGroup = try DMCardGroup.decodeFromShared(data, context: context)
            showImportAlert = true
        } catch {
            print("Preview failed: \(error)")
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
    }
}
