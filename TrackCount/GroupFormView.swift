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
    let characterLimit = 32
    
    var body: some View {
        NavigationStack {
            List {
                ZStack(alignment: .bottomTrailing) {
                    TextField("Set group title", text: $viewModel.newGroupTitle)
                        .customRoundedStyle()
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 16, trailing: 0))
                        .onChange(of: viewModel.newGroupTitle) {
                            viewModel.newGroupTitle = String(viewModel.newGroupTitle.trimmingCharacters(in: .whitespaces))
                            if viewModel.newGroupTitle.count > characterLimit {
                                viewModel.newGroupTitle = String(viewModel.newGroupTitle.prefix(characterLimit))
                            }
                        }
                    
                    Text("\(viewModel.newGroupTitle.count)/32")
                        .padding([.trailing], 3)
                        .foregroundColor(.gray)
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
                    SymbolPicker(behaviour: .tapWithUnselect, selectedSymbol: $viewModel.newGroupSymbol)
                        .presentationDetents([.fraction(0.99)])
                }
                .listRowSeparator(.hidden)
                
                Button(action : {
                    viewModel.addGroup(with: context)
                    if viewModel.validationError.isEmpty {
                        dismiss()
                    }
                }) {
                    Text(viewModel.selectedGroup == nil ? "Add Group" : "Save Group")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .listRowSeparator(.hidden)
                
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError.joined(separator: ", "))
                        .listRowSeparator(.hidden)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .listStyle(InsetListStyle())
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
        }
    }
}

#Preview {
    // Sample CardViewModel to pass into the preview
    let testViewModel = GroupViewModel()
    
    GroupFormView(viewModel: testViewModel)
        .modelContainer(for: DMCardGroup.self)
}
