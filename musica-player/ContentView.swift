//
//  ContentView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct ContentView: View {
    // Playlists and players for each side
    @StateObject private var playlist1 = Playlist()
    @StateObject private var player1: MusicPlayer
    
    @StateObject private var playlist2 = Playlist()
    @StateObject private var player2: MusicPlayer
    
    init() {
        // Create instances correctly
        let p1 = Playlist()
        let pl1 = MusicPlayer(playlist: p1)
        _playlist1 = StateObject(wrappedValue: p1)
        _player1 = StateObject(wrappedValue: pl1)
        
        let p2 = Playlist()
        let pl2 = MusicPlayer(playlist: p2)
        _playlist2 = StateObject(wrappedValue: p2)
        _player2 = StateObject(wrappedValue: pl2)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top status bar
            StatusBarView(
                onOpenPlayer1: {},
                onOpenPlayer2: {},
                player1: player1,
                player2: player2
            )
            
            Divider()
            
            // Players
            HStack(spacing: 0) {
                PlayerView(
                    playerName: "Player 1",
                    playlist: playlist1,
                    player: player1
                )
                Divider()
                PlayerView(
                    playerName: "Player 2",
                    playlist: playlist2,
                    player: player2
                )
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
