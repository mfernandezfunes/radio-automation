//
//  StatusBarView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct StatusBarView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var currentTime = Date()
    var onAutoArrange: (() -> Void)? = nil
    var onOpenPlayer1: (() -> Void)? = nil
    var onOpenPlayer2: (() -> Void)? = nil
    var player1: MusicPlayer? = nil
    var player2: MusicPlayer? = nil
    
    init(onAutoArrange: (() -> Void)? = nil, onOpenPlayer1: (() -> Void)? = nil, onOpenPlayer2: (() -> Void)? = nil, player1: MusicPlayer? = nil, player2: MusicPlayer? = nil) {
        self.onAutoArrange = onAutoArrange
        self.onOpenPlayer1 = onOpenPlayer1
        self.onOpenPlayer2 = onOpenPlayer2
        self.player1 = player1
        self.player2 = player2
    }
    
    var body: some View {
        HStack(spacing: 30) {
            // Player 1 button
            Button(action: {
                onOpenPlayer1?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title3)
                    Text("Player 1")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Current Time and buttons
            VStack(alignment: .center, spacing: 8) {
                Text(currentTime, style: .time)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    // AutoPlay toggle button
                    if let player1 = player1, let player2 = player2 {
                        AutoPlayToggleButton(player1: player1, player2: player2)
                    }
                    
                    // Silence Detection toggle button (always visible if players exist)
                    if let player1 = player1, let player2 = player2 {
                        SilenceDetectionToggleButton(player1: player1, player2: player2)
                    }
                    
                    Button(action: {
                        onAutoArrange?()
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Auto-arrange player windows")
                    
                    Button(action: {
                        openWindow(id: "config")
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Abrir configuración")
                    
                    Button(action: {
                        openWindow(id: "audioOutput")
                    }) {
                        Image(systemName: "speaker.wave.3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Salida de Audio - Equalizador global")
                }
            }
            
            Spacer()
            
            // Player 2 button
            Button(action: {
                onOpenPlayer2?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title3)
                    Text("Player 2")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 70)
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

// Helper view to observe player changes
private struct AutoPlayToggleButton: View {
    @ObservedObject var player1: MusicPlayer
    @ObservedObject var player2: MusicPlayer
    
    private var isAutoPlayEnabled: Bool {
        player1.autoPlayNext && player2.autoPlayNext
    }
    
    var body: some View {
        Button(action: {
            let newValue = !isAutoPlayEnabled
            player1.autoPlayNext = newValue
            player2.autoPlayNext = newValue
        }) {
            Image(systemName: isAutoPlayEnabled ? "play.circle.fill" : "play.circle")
                .font(.title3)
                .foregroundColor(isAutoPlayEnabled ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .help(isAutoPlayEnabled ? "AutoPlay activado" : "Activar AutoPlay en ambos players")
    }
}

// Helper view for silence detection toggle
private struct SilenceDetectionToggleButton: View {
    @ObservedObject var player1: MusicPlayer
    @ObservedObject var player2: MusicPlayer
    
    // Show as enabled if at least one player has it enabled (or both)
    // This makes the button more forgiving and easier to toggle
    private var isSilenceDetectionEnabled: Bool {
        player1.silenceDetectionEnabled || player2.silenceDetectionEnabled
    }
    
    var body: some View {
        Button(action: {
            // Toggle based on current state
            // If at least one is enabled, disable both
            // If both are disabled, enable both
            let shouldEnable = !isSilenceDetectionEnabled
            
            // When enabling, ensure default behavior is auto-stop (not advance)
            if shouldEnable {
                // Set default behavior: auto-stop, not advance
                player1.autoStopOnSilence = true
                player1.autoPlayFallbackOnSilence = false
                player2.autoStopOnSilence = true
                player2.autoPlayFallbackOnSilence = false
            }
            
            player1.silenceDetectionEnabled = shouldEnable
            player2.silenceDetectionEnabled = shouldEnable
        }) {
            Image(systemName: isSilenceDetectionEnabled ? "speaker.slash.fill" : "speaker.slash")
                .font(.title3)
                .foregroundColor(isSilenceDetectionEnabled ? .orange : .secondary)
        }
        .buttonStyle(.plain)
        .help(isSilenceDetectionEnabled ? "Detección de silencios activada - Clic para desactivar" : "Activar detección de silencios en ambos players")
    }
}

#Preview {
    StatusBarView()
        .frame(width: 1000)
}

