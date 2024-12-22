//
//  SymbolPicker.swift
//  TrackCount
//
//  Contains symbols and a symbol picker functionality
//


import SwiftUI

struct SymbolPicker: View {
    @Binding var selectedSymbol: String
    @Environment(\.presentationMode) var presentationMode
    private let mathSymbols = ["plus", "minus", "multiply", "divide", "number"]
    
    private let transportSymbols = ["car.fill", "car.2.fill", "bolt.car.fill", "bus.fill", "bus.doubledecker.fill", "tram.fill", "airplane", "fuelpump.fill", "bicycle", "figure.walk"]
    
    private let timeSymbols = ["clock.fill", "alarm.fill", "stopwatch.fill", "timer", "hourglass",]
    
    private let columns = [
        GridItem(.adaptive(minimum: 50))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Math")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: mathSymbols)
                    Divider().padding(.vertical)
                    
                    Text("Transportation")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: transportSymbols)
                    Divider().padding(.vertical)
                    
                    Text("Time")
                        .font(.headline)
                        .padding(.horizontal)
                    createSymbolGrid(symbols: timeSymbols)
                }
            }
            .navigationBarTitle("Icons", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Function to create a LazyVGrid for a given set of symbols
    private func createSymbolGrid(symbols: [String]) -> some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(symbols, id: \.self) { symbol in
                Image(systemName: symbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding()
                    .background(selectedSymbol == symbol ? Color.blue.opacity(0.3) : Color.clear)
                    .foregroundStyle(Color.secondary)
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedSymbol = symbol
                    }
            }
        }
    }
}

struct SymbolPicker_Previews: PreviewProvider {
    static var previews: some View {
        SymbolPicker(selectedSymbol: .constant("star"))
    }
}
