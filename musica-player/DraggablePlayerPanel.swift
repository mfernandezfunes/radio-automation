//
//  DraggablePlayerPanel.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct DraggablePlayerPanel: View {
    let playerName: String
    @ObservedObject var playlist: Playlist
    @ObservedObject var player: MusicPlayer
    var otherPlayer: MusicPlayer? // Reference to the other player for commands
    @Binding var autoArrangeTrigger: Int
    let containerSize: CGSize
    let visiblePanels: Int // Number of visible panels (1 or 2)
    @State private var position: CGPoint = .zero
    @State private var dragStart: CGPoint = .zero
    @State private var panelSize: CGSize = CGSize(width: 500, height: 800)
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar for dragging
            HStack {
                Text(playerName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .contentShape(Rectangle())
            
            // Player status information
            PlayerStatusView(
                playerName: playerName,
                playlist: playlist,
                player: player
            )
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Player content
            PlayerView(
                playerName: playerName,
                playlist: playlist,
                player: player,
                otherPlayer: otherPlayer
            )
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragStart == .zero {
                        dragStart = position
                    }
                    position = CGPoint(
                        x: dragStart.x + value.translation.width,
                        y: dragStart.y + value.translation.height
                    )
                }
                .onEnded { _ in
                    dragStart = .zero
                }
        )
        .onChange(of: autoArrangeTrigger) { _ in
            arrangePosition(in: containerSize)
        }
        .onChange(of: containerSize) { newSize in
            arrangePosition(in: newSize)
        }
        .onAppear {
            arrangePosition(in: containerSize)
        }
    }
    
    private func arrangePosition(in size: CGSize) {
        let statusBarHeight: CGFloat = 70
        let availableHeight = size.height - statusBarHeight
        let spacing: CGFloat = 20
        let padding: CGFloat = 20
        
        // Calculate panel size based on available space and number of visible panels
        let availableWidth = size.width - (padding * 2)
        
        if visiblePanels == 1 {
            // Single panel: use most of the available space
            panelSize = CGSize(
                width: min(availableWidth - spacing, 800),
                height: min(availableHeight - spacing, 900)
            )
            
            // Center the single panel
            position = CGPoint(
                x: size.width / 2,
                y: statusBarHeight + availableHeight / 2
            )
        } else {
            // Two panels: divide space equally
            let panelWidth = (availableWidth - spacing) / 2
            panelSize = CGSize(
                width: min(panelWidth, 600),
                height: min(availableHeight - spacing, 900)
            )
            
            if playerName == "Player 1" {
                // Position on the left
                position = CGPoint(
                    x: padding + panelSize.width / 2,
                    y: statusBarHeight + availableHeight / 2
                )
            } else {
                // Position on the right
                position = CGPoint(
                    x: size.width - padding - panelSize.width / 2,
                    y: statusBarHeight + availableHeight / 2
                )
            }
        }
    }
}

