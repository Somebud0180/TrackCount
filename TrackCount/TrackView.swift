//
//  TrackView.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData

struct TrackView: View {
    @Environment(\.modelContext) private var context
    
    // Set variable defaults
    var selectedGroup: DMCardGroup
    
    var body: some View {
        ScrollView {
            Grid() {
                ForEach(selectedGroup.cards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                    if card.type == .counter {
                        Text(card.title)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                        HStack {
                            ForEach(0..<card.count, id: \.self) { index in
                                toggleButton(card, id: index)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func toggleButton(_ card: DMStoredCard, id: Int) -> some View {
        return AnyView(
            Button(action: {
                card.state![id].toggle()
            }) {
                if let buttonText = card.buttonText, buttonText.indices.contains(id) {
                    Text(card.buttonText![id])
                        .font(.system(size: 30))
                }
                Image(systemName: card.symbol ?? "questionmark.square.dashed")
                    .imageScale(.large)
            }
                .buttonStyle(.borderedProminent)
                .tint(Color.secondary)
                .foregroundStyle(card.state![id] ? .primary : .secondary)
                .frame(maxWidth: .infinity)
        )
    }
    
    private func counterCard(_ card: DMStoredCard) -> some View {
        return AnyView(
            VStack {
                Text(card.title)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                Button(action: {card.count += 1}) {
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
                
                Text(String(card.count))
                    .font(.title)
                
                Button(action: {card.count -= 1}) {
                    Image(systemName: "minus")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DMCardGroup.self)
}
