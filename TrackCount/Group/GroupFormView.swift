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
            ZStack(alignment: .bottomTrailing) {
                TextField("Set group title", text: $viewModel.newGroupTitle)
                    .customRoundedStyle(interactive: true, tint: colorScheme == .dark ? .gray.opacity(0.4) : .white.opacity(0.8))
                    .errorOverlay("TitleSymbolEmpty", with: viewModel.validationError)
                    .onChange(of: viewModel.newGroupTitle) {
                        if viewModel.newGroupTitle.count > characterLimit {
                            viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespaces))
                            viewModel.newGroupTitle = String(viewModel.newGroupTitle.prefix(characterLimit))
                        }
                    }
                    .onSubmit {
                        viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespaces))
                    }
                
                Text("\(viewModel.newGroupTitle.count)/\(characterLimit)")
                    .padding(.trailing, 3)
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
            
            // A symbol preview/picker
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    isPickerPresented.toggle()
                }) {
                    HStack {
                        Text("Group Symbol:")
                        Spacer()
                        Image(systemName: viewModel.newGroupSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .errorOverlay("TitleSymbolEmpty", with: viewModel.validationError)
                }
                .foregroundStyle(.foreground)
                .customRoundedStyle(interactive: true, tint: colorScheme == .dark ? .gray.opacity(0.4) : .white.opacity(0.8))
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
                viewModel.saveGroup(with: context)
                if viewModel.validationError.isEmpty && viewModel.warnError.isEmpty {
                    dismiss()
                }
            }) {
                if #available(iOS 26.0, *) {
                    Text(viewModel.selectedGroup != nil ? "Add Group" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .customRoundedStyle(interactive: true, tint: .blue, padding: 6)
                        .foregroundStyle(.white)
                } else {
                    Text(viewModel.selectedGroup != nil ? "Add Group" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }.padding()
        }
    }
}

#Preview {
    // Sample CardViewModel to pass into the preview
    let testViewModel = GroupViewModel()
    
    GroupFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
