//
//  GroupFormView.swift
//  TrackCount
//
//  A view containing the group creation interface
//

import SwiftUI
import SwiftData

struct GroupFormView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: GroupViewModel
    
    // Set variable defaults
    @State private var isPickerPresented: Bool = false
    @State private var isSaveButtonPressed: Bool = false
    
    struct ValidationVariables: Equatable {
        let groupTitle: String
        let groupSymbol: String
    }
    
    var body: some View {
        // Create an array containing all variables for the onChange form validation
        var validateVariables: ValidationVariables {
            ValidationVariables(
                groupTitle: viewModel.newGroupTitle,
                groupSymbol: viewModel.newGroupSymbol
            )
        }
        
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                formView()
            }
            .padding(.top, -24)
            .navigationBarTitle(viewModel.selectedGroup != nil ? "Edit Group" : "Create Group", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveGroup(with: context)
                        if viewModel.validationError.isEmpty && viewModel.warnError.isEmpty {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            SymbolPickerView(viewBehaviour: .tapWithUnselect, selectedSymbol: $viewModel.newGroupSymbol)
                .presentationDetents([.fraction(0.95)])
        }
        .onChange(of: validateVariables) {
            if !viewModel.validationError.isEmpty {
                viewModel.validateForm()
            }
        }
    }
    
    private func formView() -> some View {
        let characterLimit = viewModel.titleCharacterLimit
        
        return Group {
            Form {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Set group title", text: $viewModel.newGroupTitle)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.newGroupTitle) {
                            if viewModel.newGroupTitle.count > characterLimit {
                                viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                                viewModel.newGroupTitle = String(viewModel.newGroupTitle.prefix(characterLimit))
                            }
                        }
                        .onSubmit {
                            viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    
                    Divider()
                    
                    // A symbol preview/picker
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack {
                            Text("Group Symbol:")
                            
                            Spacer()
                            
                            if viewModel.newGroupSymbol.isEmpty {
                                Text("Select")
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: viewModel.newGroupSymbol)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .foregroundStyle(.foreground)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("Group Smybol Picker")
                    
                    errorMessageView("TitleSymbolEmpty", with: viewModel.validationError, message: "A title or symbol is required")
                }
                
                if !viewModel.warnError.isEmpty {
                    Text(viewModel.warnError.joined(separator: ", "))
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    // Sample CardViewModel to pass into the preview
    let testViewModel = GroupViewModel()
    
    GroupFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
