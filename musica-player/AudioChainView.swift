//
//  AudioChainView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

/// Visual representation of the audio processing chain
struct AudioChainView: View {
    @ObservedObject var player: MusicPlayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cadena de Audio")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Horizontal flow diagram
            HStack(spacing: 8) {
                // Player Node
                EffectNode(
                    icon: "play.circle.fill",
                    label: "Player",
                    isActive: true,
                    color: .blue
                )
                
                Arrow()
                
                // Varispeed (always active)
                EffectNode(
                    icon: "speedometer",
                    label: "Speed",
                    isActive: true,
                    color: .purple
                )
                
                Arrow()
                
                // Delay
                EffectNode(
                    icon: "waveform.path",
                    label: "Delay",
                    isActive: player.delayEnabled,
                    color: .orange,
                    intensity: player.delayEnabled ? player.delayWetDryMix / 100.0 : 0.0
                )
                
                Arrow()
                
                // Reverb
                EffectNode(
                    icon: "music.note",
                    label: "Reverb",
                    isActive: player.reverbEnabled,
                    color: .green,
                    intensity: player.reverbEnabled ? player.reverbWetDryMix / 100.0 : 0.0
                )
                
                Arrow()
                
                // Equalizer
                EffectNode(
                    icon: "slider.horizontal.3",
                    label: "EQ",
                    isActive: player.equalizerEnabled,
                    color: .red,
                    intensity: player.equalizerEnabled ? 1.0 : 0.0
                )
                
                Arrow()
                
                // Mixer
                EffectNode(
                    icon: "slider.horizontal.below.rectangle",
                    label: "Mixer",
                    isActive: true,
                    color: .gray
                )
                
                Arrow()
                
                // Output
                EffectNode(
                    icon: "speaker.wave.3.fill",
                    label: "Output",
                    isActive: true,
                    color: .blue
                )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

/// Individual effect node in the chain
private struct EffectNode: View {
    let icon: String
    let label: String
    let isActive: Bool
    let color: Color
    var intensity: Float = 1.0
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Circle()
                    .stroke(isActive ? color : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? color : .gray)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(isActive ? .primary : .secondary)
            
            // Intensity indicator (for effects with wet/dry mix)
            if isActive && intensity > 0 && intensity < 1.0 {
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < Int(intensity * 3) ? color : Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .frame(width: 60)
    }
}

/// Arrow connector between nodes
private struct Arrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(width: 16)
    }
}

#Preview {
    AudioChainView(player: MusicPlayer(playlist: Playlist(), playerName: "Player 1"))
        .padding()
        .frame(width: 600)
}

