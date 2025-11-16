//
//  ConfigView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI

struct ConfigView: View {
    @ObservedObject var player1: MusicPlayer
    @ObservedObject var player2: MusicPlayer
    @State private var masterVolume: Float = 1.0
    @State private var player1BaseVolume: Float = 0.5
    @State private var player2BaseVolume: Float = 0.5
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Configuración")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Player 1 Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Player 1")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // BPM and Beat Indicator
                HStack(spacing: 16) {
                    if let bpm = player1.detectedBPM {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(bpm))")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("--")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Beat indicator LED
                    VStack(spacing: 4) {
                        Text("Beat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(player1.beatDetected ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(player1.beatDetected ? Color.red.opacity(0.5) : Color.clear, lineWidth: 3)
                                    .scaleEffect(player1.beatDetected ? 1.5 : 1.0)
                            )
                            .animation(.easeOut(duration: 0.1), value: player1.beatDetected)
                    }
                }
                
                // Volume slider for Player 1
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { player1BaseVolume },
                        set: { newValue in
                            player1BaseVolume = newValue
                            applyMasterVolume()
                        }
                    ), in: 0...1)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text("\(Int(player1BaseVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                
                // VU Meter for Player 1
                VStack(alignment: .leading, spacing: 8) {
                    Text("VU Meter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VUMeterView(leftLevel: player1.leftLevel, rightLevel: player1.rightLevel)
                        .frame(height: 80)
                }
                
                // VU Meter Sensitivity slider for Player 1
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sensibilidad VU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", player1.vuMeterSensitivity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        Text("Baja")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player1.vuMeterSensitivity },
                            set: { newValue in
                                player1.vuMeterSensitivity = newValue
                            }
                        ), in: 1.0...5.0)
                        
                        Text("Alta")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Player 2 Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Player 2")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // BPM and Beat Indicator
                HStack(spacing: 16) {
                    if let bpm = player2.detectedBPM {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(bpm))")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("--")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Beat indicator LED
                    VStack(spacing: 4) {
                        Text("Beat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(player2.beatDetected ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(player2.beatDetected ? Color.red.opacity(0.5) : Color.clear, lineWidth: 3)
                                    .scaleEffect(player2.beatDetected ? 1.5 : 1.0)
                            )
                            .animation(.easeOut(duration: 0.1), value: player2.beatDetected)
                    }
                }
                
                // Volume slider for Player 2
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { player2BaseVolume },
                        set: { newValue in
                            player2BaseVolume = newValue
                            applyMasterVolume()
                        }
                    ), in: 0...1)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text("\(Int(player2BaseVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                
                // VU Meter for Player 2
                VStack(alignment: .leading, spacing: 8) {
                    Text("VU Meter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VUMeterView(leftLevel: player2.leftLevel, rightLevel: player2.rightLevel)
                        .frame(height: 80)
                }
                
                // VU Meter Sensitivity slider for Player 2
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sensibilidad VU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", player2.vuMeterSensitivity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        Text("Baja")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player2.vuMeterSensitivity },
                            set: { newValue in
                                player2.vuMeterSensitivity = newValue
                            }
                        ), in: 1.0...5.0)
                        
                        Text("Alta")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            // Master Volume Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Volumen Master")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Slider(value: $masterVolume, in: 0...1) {
                        Text("Master Volume")
                    } onEditingChanged: { editing in
                        // Apply master volume in real-time
                        applyMasterVolume()
                    }
                    .onChange(of: masterVolume) { newValue in
                        // Apply master volume in real-time
                        applyMasterVolume()
                    }
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("\(Int(masterVolume * 100))%")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(width: 500)
        .frame(minHeight: 600)
        .onAppear {
            // Initialize base volumes from current player volumes
            player1BaseVolume = player1.volume
            player2BaseVolume = player2.volume
            // Initialize master volume to 1.0 (100%)
            masterVolume = 1.0
            // Apply initial master volume
            applyMasterVolume()
        }
    }
    
    private func applyMasterVolume() {
        // Apply master volume as a multiplier to base volumes
        // This allows individual control while having a master control
        player1.volume = player1BaseVolume * masterVolume
        player2.volume = player2BaseVolume * masterVolume
    }
}

#Preview {
    let playlist1 = Playlist()
    let player1 = MusicPlayer(playlist: playlist1)
    let playlist2 = Playlist()
    let player2 = MusicPlayer(playlist: playlist2)
    
    return ConfigView(player1: player1, player2: player2)
}

