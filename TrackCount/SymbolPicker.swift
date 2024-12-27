//
//  SymbolPicker.swift
//  TrackCount
//
//  Contains symbols and a symbol picker functionality
//


import SwiftUI


/// Represents the interaction behavior setting for the symbol picker.
enum Behaviour {
    case tapToSelect // Tap to select
    case tapWithUnselect // Tap to select and tap again to unselect
}

/// A view containing symbols with the ability to pick one and store it to selectedSymbol.
struct SymbolPicker: View {
    @Binding var selectedSymbol: String
    @Environment(\.presentationMode) var presentationMode
    
    private let behaviour: Behaviour
    
    // Initialize with originScreen and selectedSymbol binding
    /// Initializes the behaviour and selected symbol binding
    /// - Parameters:
    ///   - behaviour: accepts tapToSelect which allows tapping the symbol to select or tapWithUnselect which also allows to unselect the symbol by tapping it again
    ///   - selectedSymbol: accepts a variable to modify with the selected symbol
    init(behaviour: Behaviour, selectedSymbol: Binding<String>) {
        self.behaviour = behaviour
        self._selectedSymbol = selectedSymbol
    }
    
    // Symbols
    private let objectSymbols = ["hammer.fill", "wrench.fill", "screwdriver.fill", "paintbrush.fill", "scissors", "pencil", "text.document.fill", "list.clipboard.fill", "archivebox.fill", "tray.2.fill", "bag.fill", "cart.fill", "gift.fill", "lightbulb.fill", "fanblades.fill", "microwave.fill", "oven.fill", "fork.knife", "cup.and.saucer.fill", "book.fill", "umbrella.fill", "balloon.fill", "party.popper.fill"]
    
    private let mathSymbols = ["plus", "minus", "multiply", "divide", "number"]
    
    private let transportSymbols = ["car.fill", "car.2.fill", "bolt.car.fill", "bus.fill", "bus.doubledecker.fill", "tram.fill", "airplane", "fuelpump.fill", "bicycle", "figure.walk"]
    
    private let timeSymbols = ["clock.fill", "alarm.fill", "stopwatch.fill", "timer", "hourglass",]
    
    private let natureSymbols = ["cloud.sun.fill", "cloud.bolt.fill", "cloud.rain.fill", "cloud.bolt.rain.fill", "cloud.snow.fill", "cloud.hail.fill", "snowflake", "wind", "wind.snow", "tornado", "thermometer", "flame.fill", "sun.max.fill", "star.fill", "moon.fill", "moon.stars.fill"]
    
    private let technologySymbols = ["laptopcomputer", "iphone", "ipad", "desktopcomputer", "applewatch", "watch.analog", "tv.fill", "printer.fill", "network", "antenna.radiowaves.left.and.right"]
    
    private let peopleSymbols = ["person.fill", "person.2.fill", "person.circle", "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark", "figure.wave", "figure.run", "figure.walk", "figure.stand"]
    
    private let foodSymbols = ["fork.knife", "cup.and.saucer.fill", "leaf.fill", "cart.fill", "takeoutbag.and.cup.and.straw.fill"]
    
    private let animalSymbols = ["hare.fill", "tortoise.fill", "cat.fill", "dog.fill", "lizard.fill", "bird.fill", "ant.fill", "ladybug.fill", "fish.fill", "pawprint.fill"]
    
    private let fitnessSymbols = ["gamecontroller.fill", "trophy.fill", "figure.roll", "figure.dance", "figure.strengthtraining.traditional", "figure.surfing", "figure.pool.swim", "figure.run.treadmill", "figure.boxing", "figure.badminton", "figure.hiking", "figure.walk", "figure.run", "figure.golf", "sportscourt.fill", "soccerball", "basketball.fill", "volleyball.fill", "football.fill", "tennis.racket", "tennisball.fill", "hockey.puck.fill"]

    private let columns = [
        GridItem(.adaptive(minimum: 50))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Objects")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: objectSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Math")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: mathSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Transportation")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: transportSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Time")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: timeSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Nature")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: natureSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Technology")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: technologySymbols)
                    Spacer(minLength: 20)
                    
                    Text("People")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: peopleSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Food")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: foodSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Animal")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: animalSymbols)
                    Spacer(minLength: 20)
                    
                    Text("Fitness")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: fitnessSymbols)
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitle("Icons", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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
    /// The behaviour changes based on the passed over argument
    ///
    private func handleSymbolSelection(_ symbol: String) {
        switch behaviour {
        case .tapToSelect:
            // If the symbol is already selected, deselect it
            if selectedSymbol == symbol {
                selectedSymbol = ""
            } else {
                // Select the symbol and dismiss the picker
                selectedSymbol = symbol
                presentationMode.wrappedValue.dismiss()
            }
        case .tapWithUnselect:
            // Similarly handle for GroupFormView
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
    SymbolPicker(behaviour: .tapToSelect, selectedSymbol: .constant("balloon.fill"))
}
