//
//  musica_playerApp.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

@main
struct musica_playerApp: App {
    // Shared state for playlists and players
    @StateObject private var playlist1 = Playlist()
    @StateObject private var player1: MusicPlayer
    @StateObject private var playlist2 = Playlist()
    @StateObject private var player2: MusicPlayer
    
    init() {
        // Create instances correctly
        let p1 = Playlist()
        let pl1 = MusicPlayer(playlist: p1, playerName: "Player 1")
        let p2 = Playlist()
        let pl2 = MusicPlayer(playlist: p2, playerName: "Player 2")
        
        // Set cross-references for command execution
        pl1.otherPlayer = pl2
        pl2.otherPlayer = pl1
        
        _playlist1 = StateObject(wrappedValue: p1)
        _player1 = StateObject(wrappedValue: pl1)
        _playlist2 = StateObject(wrappedValue: p2)
        _player2 = StateObject(wrappedValue: pl2)
    }
    
    var body: some Scene {
        // Main window containing everything
        WindowGroup(id: "main") {
            MainWindowView(
                playlist1: playlist1,
                player1: player1,
                playlist2: playlist2,
                player2: player2
            )
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        // Configuration window - single instance
        Window("Config", id: "config") {
            ConfigView(player1: player1, player2: player2)
        }
        .defaultSize(width: 900, height: 700)
    }
}
