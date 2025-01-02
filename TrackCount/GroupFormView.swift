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
    
    // Set variable defaults
    @State private var isPickerPresented: Bool = false
    @Query private var savedGroups: [DMCardGroup]
    @State private var validationError: [String] = []
    @State private var newGroupIndex: Int = 0
    @State private var newGroupSymbol: String = ""
    @State private var newGroupTitle: String = ""
    
    let characterLimit = 32
    
    var body: some View {
        NavigationStack {
            List {
                ZStack(alignment: .bottomTrailing) {
                    TextField("Set group title", text: $newGroupTitle)
                        .customRoundedStyle()
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 16, trailing: 0))
                        .onChange(of: newGroupTitle) {
                            if newGroupTitle.count > characterLimit {
                                newGroupTitle = String(newGroupTitle.prefix(characterLimit))
                            }
                        }
                    
                    Text("\(newGroupTitle.count)/32")
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
                        Image(systemName: newGroupSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .customRoundedStyle()
                }
                .buttonStyle(PlainButtonStyle())
                .listRowSeparator(.hidden)
                .sheet(isPresented: $isPickerPresented) {
                    SymbolPicker(behaviour: .tapWithUnselect, selectedSymbol: $newGroupSymbol)
                        .presentationDetents([.fraction(0.99)])
                }
                .listRowSeparator(.hidden)
                
                Button(action : {
                    addGroup()
                    if validationError.isEmpty {
                        dismiss()
                    }
                }) {
                    Text("Add Group")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .listRowSeparator(.hidden)
                
                if !validationError.isEmpty {
                    Text(validationError.joined(separator: ", "))
                        .listRowSeparator(.hidden)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .listStyle(InsetListStyle())
            .navigationBarTitle("Create Group", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addGroup()
                        if validationError.isEmpty {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    /// A function that stores the temporary variables to a group and saves it to the data model entity.
    /// Used to save the set variables into the group.
    /// Also checks the card contents and throws errors, if any, to validationError.
    /// Also provides the group's index and uuid on save.
    private func addGroup() {
        // Validate entry
        validateGroup()
        
        guard validationError.isEmpty else {
            return
        }
        
        if savedGroups.count == 0 {
            newGroupIndex = 0
        } else {
            newGroupIndex = savedGroups.count + 1
        }
        
        let newGroup = DMCardGroup(uuid: UUID(),
                                   index: newGroupIndex,
                                   groupTitle: newGroupTitle,
                                   groupSymbol: newGroupSymbol)
        
        context.insert(newGroup)
        
        // Save the context
        do {
            try context.save()
        } catch {
            validationError.append("Failed to save the group: \(error.localizedDescription)")
        }
        
        newGroupTitle = ""
    }
    
    /// A function that checks the group's contents for any issues.
    /// Ensures atleast either one of the two variables (newGroupTitle and newGroupSymbol) is filled.
    /// Appends errors to validationError.
    private func validateGroup() {
        validationError.removeAll()
        let titleIsEmpty = newGroupTitle.isEmpty
        let symbolIsEmpty = newGroupSymbol.isEmpty
        
        if titleIsEmpty && symbolIsEmpty {
            validationError.append("Group title cannot be empty without a symbol or vice versa")
        }
    }
}

#Preview {
    GroupFormView()
        .modelContainer(for: DMCardGroup.self)
}
