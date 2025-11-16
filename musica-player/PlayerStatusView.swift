//
//  PlayerStatusView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct PlayerStatusView: View {
    let playerName: String
    @ObservedObject var playlist: Playlist
    @ObservedObject var player: MusicPlayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player name and status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(player.isPlaying ? Color.green : (playlist.currentSong != nil ? Color.orange : Color.gray))
                    .frame(width: 10, height: 10)
                Text(playerName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Song title and artist
            if let song = playlist.currentSong {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Title:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Artist:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("No song")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Time information
            if player.duration > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Played")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTime(player.currentTime))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTime(max(0, player.duration - player.currentTime)))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTime(player.duration))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let playlist = Playlist()
    let player = MusicPlayer(playlist: playlist)
    return PlayerStatusView(playerName: "Player 1", playlist: playlist, player: player)
        .padding()
}

