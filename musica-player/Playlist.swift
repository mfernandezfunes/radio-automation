//
//  Playlist.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation
import Combine
import SwiftUI

class Playlist: ObservableObject {
    @Published var items: [PlaylistItem] = []
    @Published var currentIndex: Int? = nil
    @Published var nextIndex: Int? = nil // Manually marked next song
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
    enum RepeatMode {
        case off
        case one
        case all
    }
    
    private var originalOrder: [PlaylistItem] = []
    
    // Legacy property for backward compatibility
    var songs: [Song] {
        get {
            items.compactMap { $0.song }
        }
        set {
            items = newValue.map { .song($0) }
        }
    }
    
    var currentSong: Song? {
        guard let index = currentIndex, index >= 0, index < items.count else {
            return nil
        }
        return items[index].song
    }
    
    var currentItem: PlaylistItem? {
        guard let index = currentIndex, index >= 0, index < items.count else {
            return nil
        }
        return items[index]
    }
    
    func addSong(_ song: Song) {
        items.append(.song(song))
    }
    
    func addCommand(_ command: PlaylistCommand, afterIndex: Int? = nil) {
        if let index = afterIndex, index >= 0 && index < items.count {
            // Insert after the selected item
            items.insert(.command(command), at: index + 1)
            
            // Adjust current index if necessary
            if let current = currentIndex, index < current {
                currentIndex = current + 1
            }
            
            // Adjust next index if necessary
            if let next = nextIndex, index < next {
                nextIndex = next + 1
            }
        } else {
            // Add to end if no index provided or invalid index
            items.append(.command(command))
        }
    }
    
    func addItem(_ item: PlaylistItem) {
        items.append(item)
    }
    
    func removeSong(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        items.remove(at: index)
        
        // Adjust current index if necessary
        if let current = currentIndex {
            if index == current {
                currentIndex = nil
            } else if index < current {
                currentIndex = current - 1
            }
        }
        
        // Adjust next index if necessary
        if let next = nextIndex {
            if index == next {
                nextIndex = nil
            } else if index < next {
                nextIndex = next - 1
            }
        }
    }
    
    func moveSong(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        
        // Adjust current index after moving
        if let current = currentIndex {
            if let sourceIndex = source.first {
                if sourceIndex == current {
                    currentIndex = destination > sourceIndex ? destination - 1 : destination
                } else if sourceIndex < current && destination > current {
                    currentIndex = current - 1
                } else if sourceIndex > current && destination <= current {
                    currentIndex = current + 1
                }
            }
        }
        
        // Adjust next index after moving
        if let next = nextIndex {
            if let sourceIndex = source.first {
                if sourceIndex == next {
                    nextIndex = destination > sourceIndex ? destination - 1 : destination
                } else if sourceIndex < next && destination > next {
                    nextIndex = next - 1
                } else if sourceIndex > next && destination <= next {
                    nextIndex = next + 1
                }
            }
        }
    }
    
    func toggleShuffle() {
        guard !items.isEmpty else { return }
        
        if isShuffled {
            // Restore original order
            if !originalOrder.isEmpty {
                let currentItemId = currentItem?.id
                items = originalOrder
                originalOrder = []
                // Find and restore current index
                if let itemId = currentItemId, let index = items.firstIndex(where: { $0.id == itemId }) {
                    currentIndex = index
                }
            }
            isShuffled = false
        } else {
            // Save original order and shuffle (only shuffle songs, keep commands in place)
            originalOrder = items
            let currentItemId = currentItem?.id
            // Separate songs and commands
            var songsToShuffle: [PlaylistItem] = []
            var commandPositions: [(index: Int, command: PlaylistItem)] = []
            
            for (index, item) in items.enumerated() {
                if item.isCommand {
                    commandPositions.append((index: index, command: item))
                } else {
                    songsToShuffle.append(item)
                }
            }
            
            // Shuffle only songs
            songsToShuffle = songsToShuffle.shuffled()
            
            // Rebuild items array maintaining command positions
            var newItems: [PlaylistItem] = []
            var songIndex = 0
            var commandIndex = 0
            
            for i in 0..<items.count {
                if let cmdPos = commandPositions.first(where: { $0.index == i }) {
                    newItems.append(cmdPos.command)
                    commandIndex += 1
                } else if songIndex < songsToShuffle.count {
                    newItems.append(songsToShuffle[songIndex])
                    songIndex += 1
                }
            }
            
            items = newItems
            // Find current item in shuffled array
            if let itemId = currentItemId, let newIndex = items.firstIndex(where: { $0.id == itemId }) {
                currentIndex = newIndex
            }
            isShuffled = true
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .one
        case .one:
            repeatMode = .all
        case .all:
            repeatMode = .off
        }
    }
    
    func nextItem() -> PlaylistItem? {
        guard let index = currentIndex, !items.isEmpty else { return nil }
        
        // If there's a manually marked next item, use it
        if let markedNext = nextIndex, markedNext >= 0 && markedNext < items.count {
            currentIndex = markedNext
            nextIndex = nil // Clear the marked next after using it
            return items[markedNext]
        }
        
        // Otherwise, calculate next normally
        let calculatedNext = index + 1
        if calculatedNext < items.count {
            currentIndex = calculatedNext
            return items[calculatedNext]
        } else if repeatMode == .all {
            // Start from beginning
            currentIndex = 0
            return items[0]
        }
        return nil
    }
    
    func nextSong() -> Song? {
        return nextItem()?.song
    }
    
    func previousSong() -> Song? {
        guard let index = currentIndex, !items.isEmpty else { return nil }
        
        let previousIndex = index - 1
        if previousIndex >= 0 {
            currentIndex = previousIndex
            return items[previousIndex].song
        } else if repeatMode == .all {
            // Go to end
            let lastIndex = items.count - 1
            currentIndex = lastIndex
            return items[lastIndex].song
        }
        return nil
    }
    
    // Peek at the next item without advancing the index
    func peekNextItem() -> PlaylistItem? {
        guard let index = currentIndex, !items.isEmpty else { return nil }
        
        // If there's a manually marked next item, return it
        if let markedNext = nextIndex, markedNext >= 0 && markedNext < items.count {
            return items[markedNext]
        }
        
        // Otherwise, calculate next normally without changing currentIndex
        let calculatedNext = index + 1
        if calculatedNext < items.count {
            return items[calculatedNext]
        } else if repeatMode == .all {
            // Start from beginning
            return items[0]
        }
        return nil
    }
    
    func getNextIndex() -> Int? {
        // If there's a manually marked next item, return it
        if let markedNext = nextIndex {
            return markedNext
        }
        
        // Otherwise, calculate next normally
        guard let index = currentIndex, !items.isEmpty else { return nil }
        
        let calculatedNext = index + 1
        if calculatedNext < items.count {
            return calculatedNext
        } else if repeatMode == .all {
            // Start from beginning
            return 0
        }
        return nil
    }
    
    func setNextIndex(_ index: Int?) {
        guard let idx = index, idx >= 0 && idx < items.count else {
            nextIndex = nil
            return
        }
        nextIndex = idx
    }
}

