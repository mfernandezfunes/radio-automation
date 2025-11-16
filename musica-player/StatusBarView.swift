//
//  StatusBarView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct StatusBarView: View {
    @State private var currentTime = Date()
    let player1State: PlayerState
    let player2State: PlayerState
    
    struct PlayerState {
        let name: String
        let isPlaying: Bool
        let currentSong: String?
        let currentArtist: String?
        let currentTime: TimeInterval
        let duration: TimeInterval
        
        var remainingTime: TimeInterval {
            max(0, duration - currentTime)
        }
        
        func formatTime(_ time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    init(player1State: PlayerState, player2State: PlayerState) {
        self.player1State = player1State
        self.player2State = player2State
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Player 1 Status - Table format
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(player1State.isPlaying ? Color.green : (player1State.currentSong != nil ? Color.orange : Color.gray))
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Player name
                    Text(player1State.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Song title and artist
                    if let song = player1State.currentSong {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Title:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(song)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            if let artist = player1State.currentArtist {
                                Text("Artist:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                Text(artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Text("No song")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Time information
                    if player1State.duration > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Played")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player1State.formatTime(player1State.currentTime))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Left")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player1State.formatTime(player1State.remainingTime))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player1State.formatTime(player1State.duration))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
            
            // Current Time
            VStack(alignment: .center, spacing: 0) {
                Text(currentTime, style: .time)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Player 2 Status - Table format
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .trailing, spacing: 8) {
                    // Player name
                    Text(player2State.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Song title and artist
                    if let song = player2State.currentSong {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Title:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(song)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            if let artist = player2State.currentArtist {
                                Text("Artist:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                Text(artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Text("No song")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Time information
                    if player2State.duration > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 16) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Total")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player2State.formatTime(player2State.duration))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Left")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player2State.formatTime(player2State.remainingTime))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Played")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(player2State.formatTime(player2State.currentTime))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Circle()
                    .fill(player2State.isPlaying ? Color.green : (player2State.currentSong != nil ? Color.orange : Color.gray))
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 100)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .onAppear {
            // Update time every second
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

#Preview {
    StatusBarView(
        player1State: StatusBarView.PlayerState(
            name: "Player 1",
            isPlaying: true,
            currentSong: "Example Song",
            currentArtist: "Example Artist",
            currentTime: 125.0,
            duration: 240.0
        ),
        player2State: StatusBarView.PlayerState(
            name: "Player 2",
            isPlaying: false,
            currentSong: nil,
            currentArtist: nil,
            currentTime: 0,
            duration: 0
        )
    )
    .frame(width: 1000)
}

