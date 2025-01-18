//
//  GuideListView.swift
//  TrackCount
//
//  Lists the guides from Guides.json and provides access to them via GuideFileView
//

import SwiftUI

struct Guide: Codable, Identifiable {
    let id: Int
    let title: String
    let videoFilename: String
    let description: String
}

struct GuideListView: View {
    @State private var guides: [Guide] = []

    var body: some View {
        NavigationView {
            List(guides) { guide in
                NavigationLink(destination: GuideFileView(guide: guide)) {
                    Text(guide.title)
                }
            }
            .onAppear {
                loadGuides()
            }
        }
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
