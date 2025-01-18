//
//  GroupListView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// A view containing that lists all saved groups and provides access to editing the group's cards.
struct GroupListView: View {
    @EnvironmentObject private var importManager: ImportManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = GroupViewModel()
    @Environment(\.modelContext) private var context
    
    @AppStorage("gradientAnimated") var isGradientAnimated: Bool = DefaultSettings.gradientAnimated
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isShowingFilePicker = false
    @State private var isPresentingGroupForm: Bool = false
    @State private var isPresentingDeleteDialog: Bool = false
    @State private var selectedGroup: DMCardGroup?
    @State private var animateGradient: Bool = false
    
    let columnLayout: [GridItem] = [
        GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)
    ]
    
    var backgroundGradient: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { _ in
            LinearGradient(
                gradient: Gradient(colors: [primaryThemeColor.color.opacity(0.8), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .hueRotation(.degrees(animateGradient ? 30 : 0))
            .task {
                if isGradientAnimated {
                    withAnimation(.easeInOut(duration: 2).repeatForever()) {
                        animateGradient.toggle()
                    }
                }
            }
            .frame(height: 250)
            .edgesIgnoringSafeArea(.all)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                backgroundGradient
                
                ScrollView {
                    // Display logic error if any
                    if !viewModel.logicError.isEmpty {
                        Text(viewModel.logicError.joined(separator: ", "))
                            .foregroundStyle(.red)
                            .padding()
                    }
                    
                    if savedGroups.isEmpty {
                        Text("Create a new group by tapping on the plus icon")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    
                    LazyVGrid(columns: columnLayout, spacing: 16) {
                        ForEach(savedGroups) { group in
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 5)
                                NavigationLink(destination: TrackView(selectedGroup: group)) {
                                    GroupCardView(group: group)
                                        .frame(height: 200)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    contextMenu(for: group)
                                }
                            }
                        }
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle("Your Groups")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: { isPresentingGroupForm.toggle() }) {
                                    Label("New Group", systemImage: "plus.square")
                                }
                                
                                Button(action: { isShowingFilePicker = true }) {
                                    Label("Import Group", systemImage: "square.and.arrow.down")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $isPresentingGroupForm, onDismiss: {selectedGroup = nil}) {
                        GroupFormView(viewModel: viewModel)
                            .presentationDetents([.fraction(0.5)])
                            .onDisappear {
                                viewModel.validationError.removeAll()
                            }
                    }
                    .alert(isPresented: $isPresentingDeleteDialog) {
                        Alert(
                            title: alertTitle,
                            message: Text("Are you sure you want to delete this group? This cannot be undone."),
                            primaryButton: .destructive(Text("Confirm")) {
                                if let group = selectedGroup {
                                    viewModel.removeGroup(with: context, group: group)
                                    selectedGroup = nil
                                }
                            },
                            secondaryButton: .cancel {
                                selectedGroup = nil
                                isPresentingDeleteDialog = false
                            }
                        )
                    }
                    .fileImporter(
                        isPresented: $isShowingFilePicker,
                        allowedContentTypes: [.trackCountGroup],
                        allowsMultipleSelection: false
                    ) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    importManager.handleImport(url, with: context)
                                }
                            case .failure(let error):
                                viewModel.logicError.append("File import failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            .alert(importManager.previewGroup?.groupTitle.isEmpty ?? true ? "Import Group?" : "Import Group \"\(importManager.previewGroup!.groupTitle)\"?", isPresented: $importManager.showImportAlert) {
                VStack {
                    Button("Cancel", role: .cancel) {
                        importManager.reset()
                    }
                    Button("Import") {
                        importManager.confirmImport(with: context)
                    }
                }
            } message: {
                if let group = importManager.previewGroup {
                    Text("This group contains \(group.cards.count) \(group.cards.count == 1 ? "card" : "cards").")
                } else {
                    Text("Do you want to import this group?")
                }
            }
        }
        .accentColor(colorScheme == .light ? .black : .primary)
    }

    /// Computed property for alert title.
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

    
    /// A function that handles the preparation of the groups for sharing.
    /// - Parameter group: The group to be shared, accepts type DMCardGroup.
    private func shareGroup(_ group: DMCardGroup) {
        do {
            let tempURL = try viewModel.shareGroup(group)
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            // Present sharing UI
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            viewModel.logicError.append(error.localizedDescription)
        }
    }
    
    /// A function that contains the buttons used in the context menu for the cards.
    private func contextMenu(for group: DMCardGroup) -> some View {
        Group {
            NavigationLink(destination: CardListView(selectedGroup: group)) {
                Text("Edit Cards")
                Spacer()
                Image(systemName: "folder")
            }
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
}

#Preview {
    GroupListView()
        .modelContainer(for: DMCardGroup.self)
        .environmentObject(ImportManager())
}
