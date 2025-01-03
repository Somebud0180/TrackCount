//
//  ImportGroupView.swift
//  TrackCount
//
//  A view containing the import screen
//


import SwiftUI
import SwiftData

struct ImportGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let fileURL: URL
    @State private var showError = false
    @State private var errorMessage = "Failed to import group"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Importing from \(fileURL.lastPathComponent)")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Text("Import Group")
                    .font(.headline)
                
                Text("Do you want to import this group to TrackCount?")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Import to TrackCount") {
                    importGroup()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Import Group")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("ImportGroupView appeared with URL: \(fileURL.absoluteString)")
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func importGroup() {
        do {
            print("Starting import from: \(fileURL.absoluteString)") // Debug log
            let data = try Data(contentsOf: fileURL)
            let importedGroup = try DMCardGroup.decodeFromShared(data, context: modelContext)
            modelContext.insert(importedGroup)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    ImportGroupView(fileURL: URL(fileURLWithPath: ""))
        .modelContainer(for: DMCardGroup.self)
}
