//
//  CardIndexManager.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 12/24/24.
//


import Foundation

class CardIndexManager {
    private static let nextCardIndexKey = "NextCardIndex"
    private static let freeIndexesKey = "FreeIndexes"
    
    static var nextCardIndex: Int {
        get { UserDefaults.standard.integer(forKey: nextCardIndexKey) }
        set { UserDefaults.standard.set(newValue, forKey: nextCardIndexKey) }
    }
    
    static var freeIndexes: [Int] {
        get { UserDefaults.standard.array(forKey: freeIndexesKey) as? [Int] ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: freeIndexesKey) }
    }
    
    static func getNextAvailable() -> Int {
        if !freeIndexes.isEmpty {
            // Use the first free Index and remove it from the pool
            return freeIndexes.removeFirst()
        } else {
            // No free Indexes, use the next available Index
            let Index = nextCardIndex
            nextCardIndex += 1
            return Index
        }
    }
    
    static func freeIndex(_ Index: Int) {
        // Add the Index to the free list if it's not already there
        if !freeIndexes.contains(Index) {
            freeIndexes.append(Index)
            freeIndexes.sort() // Optional: Keep Indexes sorted for better predictability
        }
    }
    
    // Reset free indexes
    static func clearFreeIndex() {
        freeIndexes = []
    }
}
