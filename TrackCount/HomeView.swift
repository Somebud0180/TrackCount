//
//  HomeView.swift
//  TrackCount
//
//  Contains the home screen
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query private var savedGroups: [DMCardGroup]
    @State private var animateGradient: Bool = false

    /// Dynamically computes gradient colors based on colorScheme.
    private var gradientColors: [Color] {
        colorScheme == .light ? [.white, .blue] : [.black, .gray]
    }
    
    var body: some View {
        let backgroundGradient = LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        
        NavigationStack {
            GeometryReader { proxy in
                ZStack{
                    Rectangle()
                        .foregroundStyle(backgroundGradient)
                        .edgesIgnoringSafeArea(.all)
                        .hueRotation(.degrees(animateGradient ? 45 : 0))
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                            ){
                                animateGradient.toggle()
                            }
                        }

                    if colorScheme == .light {
                        // A thin material to soften the gradient background
                        Rectangle()
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                    }
                    
                    VStack {
                        // Title
                        Text("TrackCount")
                            .font(.system(.largeTitle, design: .default, weight: .semibold))
                            .dynamicTypeSize(DynamicTypeSize.accessibility5)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(Color.white.opacity(0.8))
                        
                        // Buttons
                        Grid(alignment: .center) {
                            NavigationLink(destination:
                                            GroupListView(viewBehaviour: .view)
                                .environmentObject(ImportManager())
                            ){
                                Text("Track It")
                                    .font(.largeTitle)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility1)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, minHeight: 25)
                                    .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
                                    .background(.ultraThinMaterial)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            
                            NavigationLink(destination:
                                            GroupListView(viewBehaviour: .edit)
                                .environmentObject(ImportManager())
                            ){
                                Text("Edit It")
                                    .font(.largeTitle)
                                    .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility1)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, minHeight: 25)
                                    .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
                                    .background(.ultraThinMaterial)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DMCardGroup.self)
}
