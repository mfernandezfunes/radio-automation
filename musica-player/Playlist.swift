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
    @Published var songs: [Song] = []
    @Published var currentIndex: Int? = nil
    @Published var nextIndex: Int? = nil // Manually marked next song
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
    enum RepeatMode {
        case off
        case one
        case all
    }
    
    private var originalOrder: [Song] = []
    
    var currentSong: Song? {
        guard let index = currentIndex, index >= 0, index < songs.count else {
            return nil
        }
        return songs[index]
    }
    
    func addSong(_ song: Song) {
        songs.append(song)
    }
    
    func removeSong(at index: Int) {
        guard index >= 0 && index < songs.count else { return }
        
        songs.remove(at: index)
        
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
        songs.move(fromOffsets: source, toOffset: destination)
        
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
        guard !songs.isEmpty else { return }
        
        if isShuffled {
            // Restore original order
            if !originalOrder.isEmpty {
                let currentSongId = currentSong?.id
                songs = originalOrder
                originalOrder = []
                // Find and restore current index
                if let songId = currentSongId, let index = songs.firstIndex(where: { $0.id == songId }) {
                    currentIndex = index
                }
            }
            isShuffled = false
        } else {
            // Save original order and shuffle
            originalOrder = songs
            let currentSongId = currentSong?.id
            songs = songs.shuffled()
            // Find current song in shuffled array
            if let songId = currentSongId, let newIndex = songs.firstIndex(where: { $0.id == songId }) {
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
    
    func nextSong() -> Song? {
        guard let index = currentIndex, !songs.isEmpty else { return nil }
        
        // If there's a manually marked next song, use it
        if let markedNext = nextIndex, markedNext >= 0 && markedNext < songs.count {
            currentIndex = markedNext
            nextIndex = nil // Clear the marked next after using it
            return songs[markedNext]
        }
        
        // Otherwise, calculate next normally
        let calculatedNext = index + 1
        if calculatedNext < songs.count {
            currentIndex = calculatedNext
            return songs[calculatedNext]
        } else if repeatMode == .all {
            // Start from beginning
            currentIndex = 0
            return songs[0]
        }
        return nil
    }
    
    func previousSong() -> Song? {
        guard let index = currentIndex, !songs.isEmpty else { return nil }
        
        let previousIndex = index - 1
        if previousIndex >= 0 {
            currentIndex = previousIndex
            return songs[previousIndex]
        } else if repeatMode == .all {
            // Go to end
            let lastIndex = songs.count - 1
            currentIndex = lastIndex
            return songs[lastIndex]
        }
        return nil
    }
    
    func getNextIndex() -> Int? {
        // If there's a manually marked next song, return it
        if let markedNext = nextIndex {
            return markedNext
        }
        
        // Otherwise, calculate next normally
        guard let index = currentIndex, !songs.isEmpty else { return nil }
        
        let calculatedNext = index + 1
        if calculatedNext < songs.count {
            return calculatedNext
        } else if repeatMode == .all {
            // Start from beginning
            return 0
        }
        return nil
    }
    
    func setNextIndex(_ index: Int?) {
        guard let idx = index, idx >= 0 && idx < songs.count else {
            nextIndex = nil
            return
        }
        nextIndex = idx
    }
}

