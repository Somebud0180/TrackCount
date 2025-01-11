//
//  GroupFormView.swift
//  TrackCount
//
//  A view containing the group creation interface
//

import SwiftUI
import SwiftData

struct GroupFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: GroupViewModel
    
    // Set variable defaults
    @State private var isPickerPresented: Bool = false
    
    var body: some View {
        let characterLimit = viewModel.titleCharacterLimit
        
        NavigationStack {
            List {
                ZStack(alignment: .bottomTrailing) {
                    TextField("Set group title", text: $viewModel.newGroupTitle)
                        .customRoundedStyle()
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 16, trailing: 0))
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
                        .padding([.trailing], 3)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
                .listRowSeparator(.hidden)
                
                // A symbol preview/picker
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
                    .customRoundedStyle()
                }
                .buttonStyle(PlainButtonStyle())
                .listRowSeparator(.hidden)
                .sheet(isPresented: $isPickerPresented) {
                    SymbolPickerView(viewBehaviour: .tapWithUnselect, selectedSymbol: $viewModel.newGroupSymbol)
                        .presentationDetents([.fraction(0.99)])
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(viewModel.selectedGroup == nil ? "Create Group" : "Edit Group", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addGroup(with: context)
                        if viewModel.validationError.isEmpty {
                            dismiss()
                        }
                    }
                }
            }
            
            if !viewModel.validationError.isEmpty {
                Text(viewModel.validationError.joined(separator: ", "))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            Button(action : {
                viewModel.addGroup(with: context)
                if viewModel.validationError.isEmpty {
                    dismiss()
                }
            }) {
                Text(viewModel.selectedGroup == nil ? "Add Group" : "Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

#Preview {
    // Sample CardViewModel to pass into the preview
    let testViewModel = GroupViewModel()
    
    GroupFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
