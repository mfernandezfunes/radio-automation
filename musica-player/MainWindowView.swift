//
//  MainWindowView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct MainWindowView: View {
    @ObservedObject var playlist1: Playlist
    @ObservedObject var player1: MusicPlayer
    @ObservedObject var playlist2: Playlist
    @ObservedObject var player2: MusicPlayer
    @State private var autoArrangeTrigger: Int = 0
    @State private var showPlayer1: Bool = true
    @State private var showPlayer2: Bool = true
    
    var body: some View {
        ZStack {
            LiquidGlassBackground()
            
            ZStack(alignment: .top) {
                // Background
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                // Status bar at top
                VStack(spacing: 0) {
                    StatusBarView(
                        onAutoArrange: {
                            autoArrangeTrigger += 1
                        },
                        onOpenPlayer1: {
                            // Toggle Player 1 panel visibility
                            showPlayer1.toggle()
                            if showPlayer1 {
                                autoArrangeTrigger += 1
                            }
                        },
                        onOpenPlayer2: {
                            // Toggle Player 2 panel visibility
                            showPlayer2.toggle()
                            if showPlayer2 {
                                autoArrangeTrigger += 1
                            }
                        },
                        player1: player1,
                        player2: player2
                    )
                    .zIndex(100)
                    
                    // Container for draggable panels
                    GeometryReader { geometry in
                        let visibleCount = (showPlayer1 ? 1 : 0) + (showPlayer2 ? 1 : 0)
                        
                        ZStack {
                            // Player 1 panel
                            if showPlayer1 {
                                DraggablePlayerPanel(
                                    playerName: "Player 1",
                                    playlist: playlist1,
                                    player: player1,
                                    otherPlayer: player2,
                                    autoArrangeTrigger: $autoArrangeTrigger,
                                    containerSize: geometry.size,
                                    visiblePanels: visibleCount
                                )
                            }
                            
                            // Player 2 panel
                            if showPlayer2 {
                                DraggablePlayerPanel(
                                    playerName: "Player 2",
                                    playlist: playlist2,
                                    player: player2,
                                    otherPlayer: player1,
                                    autoArrangeTrigger: $autoArrangeTrigger,
                                    containerSize: geometry.size,
                                    visiblePanels: visibleCount
                                )
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}

#Preview {
    let playlist1 = Playlist()
    let player1 = MusicPlayer(playlist: playlist1, playerName: "Player 1")
    let playlist2 = Playlist()
    let player2 = MusicPlayer(playlist: playlist2, playerName: "Player 2")
    
    player1.otherPlayer = player2
    player2.otherPlayer = player1
    
    return MainWindowView(
        playlist1: playlist1,
        player1: player1,
        playlist2: playlist2,
        player2: player2
    )
}

