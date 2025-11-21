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
    @State private var isHoveringControls = false
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
            // Leading: Player buttons grouped
            HStack(spacing: 10) {
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
                    .padding(.vertical, 9)
                    .background(
                        ZStack {
                            // Glassy material base
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                            // Sheen
                            LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .blendMode(.screen)
                        }
                    )
                    .overlay(
                        // Subtle border highlight
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

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
                    .padding(.vertical, 9)
                    .background(
                        ZStack {
                            // Glassy material base
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                            // Sheen
                            LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .blendMode(.screen)
                        }
                    )
                    .overlay(
                        // Subtle border highlight
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Center: Time and controls
            VStack(alignment: .center, spacing: 6) {
                Text(currentTime, style: .time)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(currentTime, style: .date)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if let player1 = player1, let player2 = player2 {
                        AutoPlayToggleButton(player1: player1, player2: player2)
                    }
                    if let player1 = player1, let player2 = player2 {
                        SilenceDetectionToggleButton(player1: player1, player2: player2)
                    }
                    Button(action: {
                        onAutoArrange?()
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.clear)
                    }
                    .buttonStyle(.plain)
                    .help("Auto-arrange player windows")

                    Button(action: {
                        openWindow(id: "config")
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.clear)
                    }
                    .buttonStyle(.plain)
                    .help("Abrir configuración")

                    Button(action: {
                        openWindow(id: "audioOutput")
                    }) {
                        Image(systemName: "speaker.wave.3")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.clear)
                    }
                    .buttonStyle(.plain)
                    .help("Salida de Audio - Equalizador global")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                        LinearGradient(colors: [Color.white.opacity(isHoveringControls ? 0.18 : 0.10), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .blendMode(.screen)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringControls = hovering
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 70)
        .background(
            ZStack {
                // Base material
                Rectangle().fill(.ultraThinMaterial)
                // Subtle vertical sheen
                LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blendMode(.screen)
                // Soft inner shadow via overlay gradient
                LinearGradient(colors: [Color.black.opacity(0.10), Color.clear, Color.black.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                    .blendMode(.overlay)
            }
        )
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1) // top hairline
                Spacer()
                Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1) // bottom hairline
            }
        )
        .blur(radius: 0.0)
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

