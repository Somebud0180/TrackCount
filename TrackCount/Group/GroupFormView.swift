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
            VStack {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer {
                        formView()
                    }
                } else {
                    formView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .onChange(of: validateVariables) {
                if !viewModel.validationError.isEmpty {
                    viewModel.validateForm()
                }
            }
            .navigationBarTitle(viewModel.selectedGroup != nil ? "Create Group" : "Edit Group", displayMode: .inline)
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
    }
    
    private func formView() -> some View {
        let characterLimit = viewModel.titleCharacterLimit
        
        return Group {
            TextField("Set group title", text: $viewModel.newGroupTitle)
                .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                .errorOverlay("TitleSymbolEmpty", with: viewModel.validationError)
                .onChange(of: viewModel.newGroupTitle) {
                    if viewModel.newGroupTitle.count > characterLimit {
                        viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                        viewModel.newGroupTitle = String(viewModel.newGroupTitle.prefix(characterLimit))
                    }
                }
                .onSubmit {
                    viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            
            // A symbol preview/picker
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    isPickerPresented = true
                }) {
                    HStack {
                        Text("Group Symbol:")
                        Spacer()
                        Image(systemName: viewModel.newGroupSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
                .foregroundStyle(.foreground)
                .customRoundedStyle(tint: colorScheme == . dark ? .gray : .white)
                .errorOverlay("TitleSymbolEmpty", with: viewModel.validationError)
                .accessibilityIdentifier("Group Smybol Picker")
                .sheet(isPresented: $isPickerPresented) {
                    SymbolPickerView(viewBehaviour: .tapWithUnselect, selectedSymbol: $viewModel.newGroupSymbol)
                        .presentationDetents([.fraction(0.99)])
                }
                
                errorMessageView("TitleSymbolEmpty", with: viewModel.validationError, message: "A title or symbol is required")
            }
            
            Spacer()
            
            if !viewModel.warnError.isEmpty {
                Text(viewModel.warnError.joined(separator: ", "))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            Button(action : {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isSaveButtonPressed = true
                    viewModel.saveGroup(with: context)
                    
                    if viewModel.validationError.isEmpty && viewModel.warnError.isEmpty {
                        dismiss()
                    }
                }
                
                withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                    isSaveButtonPressed = false
                }
            }) {
                Text(viewModel.selectedGroup != nil ? "Add Group" : "Save Changes")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
            }
            .customRoundedStyle(interactive: true, tint: .blue, externalPressed: isSaveButtonPressed)
        }
    }
}

#Preview {
    // Sample CardViewModel to pass into the preview
    let testViewModel = GroupViewModel()
    
    GroupFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
