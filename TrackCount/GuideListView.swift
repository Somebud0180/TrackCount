//
//  GuideListView.swift
//  TrackCount
//
//  Lists the guides from Guides.json and provides access to them via GuideFileView
//

import SwiftUI

struct Guide: Codable, Identifiable {
    let category: String
    let id: Int
    let title: String
    let videoFilename: String
    let description: String
}

struct GuideListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var guides: [Guide] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedGuides.keys.sorted(), id: \.self) { category in
                    Section(header: Text(category)) {
                        ForEach(groupedGuides[category] ?? []) { guide in
                            NavigationLink(destination: GuideFileView(guide: guide)) {
                                Text(guide.title)
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadGuides()
            }
            .navigationTitle("Guides")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accentColor(colorScheme == .light ? .black : .primary)
    }
    
    private var groupedGuides: [String: [Guide]] {
        Dictionary(grouping: guides, by: { $0.category })
    }
    
    private func loadGuides() {
        if let url = Bundle.main.url(forResource: "Guides", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([String: [Guide]].self, from: data)
                self.guides = decoded["guides"] ?? []
            } catch {
                print("Error loading Guides.json: \(error)")
            }
        } else {
            print("Guides.json not found in bundle.")
        }
    }
}

#Preview {
    GuideListView()
}
