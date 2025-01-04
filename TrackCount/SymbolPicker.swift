//
//  SymbolPicker.swift
//  TrackCount
//
//  Contains symbols and a symbol picker functionality
//

import SwiftUI

/// A view containing symbols with the ability to pick one and store it to selectedSymbol.
struct SymbolPicker: View {
    /// Represents the interaction behavior setting for the symbol picker.
    enum viewBehaviour {
        case tapToSelect // Tap to select
        case tapWithUnselect // Tap to select and tap again to unselect
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSymbol: String
    
    @State private var searchText: String = ""
    @State private var viewBehaviour: viewBehaviour
    
    /// The set of pickable symbols.
    private let symbols: [String: [String]] = [
        "objects": ["hammer.fill", "wrench.fill", "screwdriver.fill", "paintbrush.fill", "scissors", "pencil", "text.document.fill", "list.clipboard.fill", "archivebox.fill", "tray.2.fill", "bag.fill", "cart.fill", "gift.fill", "lightbulb.fill", "fanblades.fill", "microwave.fill", "oven.fill", "fork.knife", "cup.and.saucer.fill", "book.fill", "umbrella.fill", "balloon.fill", "party.popper.fill"],
        "math": ["plus", "minus", "multiply", "divide", "number"],
        "transport": ["car.fill", "car.2.fill", "bolt.car.fill", "bus.fill", "bus.doubledecker.fill", "tram.fill", "airplane", "fuelpump.fill", "bicycle", "figure.walk"],
        "nature": ["clock.fill", "alarm.fill", "stopwatch.fill", "timer", "hourglass"],
        "technology": ["laptopcomputer", "iphone", "ipad", "desktopcomputer", "applewatch", "watch.analog", "tv.fill", "printer.fill", "network", "antenna.radiowaves.left.and.right"],
        "people": ["person.fill", "person.2.fill", "person.circle", "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark", "figure.wave", "figure.run", "figure.walk", "figure.stand"],
        "food": ["fork.knife", "cup.and.saucer.fill", "mug.fill", "wineglass.fill", "waterbottle.fill", "leaf.fill", "cart.fill", "takeoutbag.and.cup.and.straw.fill"],
        "animals": ["hare.fill", "tortoise.fill", "cat.fill", "dog.fill", "lizard.fill", "bird.fill", "ant.fill", "ladybug.fill", "fish.fill", "pawprint.fill"],
        "fitness": ["gamecontroller.fill", "trophy.fill", "figure.roll", "figure.dance", "figure.strengthtraining.traditional", "figure.surfing", "figure.pool.swim", "figure.run.treadmill", "figure.boxing", "figure.badminton", "figure.hiking", "figure.walk", "figure.run", "figure.golf", "sportscourt.fill", "soccerball", "basketball.fill", "volleyball.fill", "football.fill", "tennis.racket", "tennisball.fill", "hockey.puck.fill"]
    ]
    
    /// Initializes the viewBehaviour and selected symbol binding.
    /// - Parameters:
    ///   - viewBehaviour: accepts tapToSelect which allows tapping the symbol to select or tapWithUnselect which also allows to unselect the symbol by tapping it again.
    ///   - selectedSymbol: accepts a variable to modify with the selected symbol.
    init(viewBehaviour: viewBehaviour, selectedSymbol: Binding<String>) {
        self.viewBehaviour = viewBehaviour
        self._selectedSymbol = selectedSymbol
    }
    
    
    
    private let columns = [
        GridItem(.adaptive(minimum: 50))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(filteredCategories.keys.sorted(), id: \.self) { category in
                        VStack(alignment: .leading) {
                            Text(category.capitalized)
                                .font(.headline)
                                .padding(.horizontal)
                            createSymbolGrid(symbols: filteredCategories[category] ?? [])
                            Spacer(minLength: 20)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Symbols")
            .navigationBarTitle("Symbols", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// A variable that contains the search filtered symbol variables.
    /// Searches the symbol variable in lowercase to match the casing.
    private var filteredCategories: [String: [String]] {
        symbols.mapValues { categorySymbols in
            searchText.isEmpty
            ? categorySymbols
            : categorySymbols.filter {
                // Lowercase the input to make it case-insensetive
                preprocess($0).contains(searchText.lowercased())}
        }
        .filter { !$0.value.isEmpty } // Remove empty categories
    }
    
    /// A helper function to preprocess the symbol names for better searchability.
    private func preprocess(_ symbol: String) -> String {
        symbol
            .replacingOccurrences(of: ".fill", with: "") // Remove ".fill"
            .replacingOccurrences(of: ".", with: " ") // Repalace "." with a space
    }
    
    /// A function that creates a grid containing a set symbols.
    /// Grabs symbols from the passed over argument and lists each symbols that can be tapped to select it.
    private func createSymbolGrid(symbols: [String]) -> some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(symbols, id: \.self) { symbol in
                Image(systemName: symbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .background(selectedSymbol == symbol ? Color.blue.opacity(0.3) : Color.clear)
                    .foregroundStyle(Color.secondary)
                    .cornerRadius(8)
                    .onTapGesture {
                        handleSymbolSelection(symbol)
                    }
            }
        }
        .padding(.horizontal)
    }
    
    /// A function that handles symbol selection.
    /// The viewBehaviour changes based on the passed over argument.
    private func handleSymbolSelection(_ symbol: String) {
        switch self.viewBehaviour {
        case .tapToSelect:
            // Select the symbol and dismiss the picker
            selectedSymbol = symbol
            presentationMode.wrappedValue.dismiss()
        case .tapWithUnselect:
            // Select the symbol and dismiss the picker
            // Or tap it again to unselect it
            if selectedSymbol == symbol {
                selectedSymbol = ""
            } else {
                selectedSymbol = symbol
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    // Sample variable to pass to the picker
    @Previewable @State var testSymbol: String = ""
    SymbolPicker(viewBehaviour: .tapWithUnselect, selectedSymbol: $testSymbol)
}
