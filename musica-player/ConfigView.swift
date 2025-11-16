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
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Configuración")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Players side by side
                HStack(alignment: .top, spacing: 20) {
                    // Player 1 Section
                    playerSection(player: player1, baseVolume: $player1BaseVolume, title: "Player 1")
                    
                    // Player 2 Section
                    playerSection(player: player2, baseVolume: $player2BaseVolume, title: "Player 2")
                }
                
                Divider()
                
                // Audio Effects side by side
                HStack(alignment: .top, spacing: 20) {
                    // Effects for Player 1
                    effectsSection(player: player1, title: "Efectos - Player 1")
                    
                    // Effects for Player 2
                    effectsSection(player: player2, title: "Efectos - Player 2")
                }
                
                Divider()
                
                // Master Volume and AirPlay side by side (at the bottom)
                HStack(alignment: .top, spacing: 20) {
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
                                applyMasterVolume()
                            }
                            .onChange(of: masterVolume) { newValue in
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
                    .frame(maxWidth: .infinity)
                    
                    // AirPlay Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AirPlay")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "airplayaudio")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Salida de Audio")
                                    .font(.subheadline)
                                Text("Selecciona AirPlay desde Preferencias del Sistema → Sonido")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .frame(width: 900)
        .frame(minHeight: 600)
        .onAppear {
            masterVolume = 1.0
            player1BaseVolume = player1.volume
            player2BaseVolume = player2.volume
        }
        .onChange(of: player1.volume) { _ in
            if masterVolume > 0.01 {
                player1BaseVolume = player1.volume / masterVolume
            }
        }
        .onChange(of: player2.volume) { _ in
            if masterVolume > 0.01 {
                player2BaseVolume = player2.volume / masterVolume
            }
        }
    }
    
    @ViewBuilder
    private func playerSection(player: MusicPlayer, baseVolume: Binding<Float>, title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // BPM and Beat Indicator
            HStack(spacing: 16) {
                if let bpm = player.detectedBPM {
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
                        .fill(player.beatDetected ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(player.beatDetected ? Color.red.opacity(0.5) : Color.clear, lineWidth: 3)
                                .scaleEffect(player.beatDetected ? 1.5 : 1.0)
                        )
                        .animation(.easeOut(duration: 0.1), value: player.beatDetected)
                }
            }
            
            // Volume slider
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Slider(value: Binding(
                    get: { player.volume },
                    set: { newValue in
                        if masterVolume > 0.01 {
                            baseVolume.wrappedValue = newValue / masterVolume
                        } else {
                            baseVolume.wrappedValue = newValue
                        }
                        applyMasterVolume()
                    }
                ), in: 0...1)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("\(Int(player.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            // VU Meter
            VStack(alignment: .leading, spacing: 8) {
                Text("VU Meter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                VUMeterView(leftLevel: player.leftLevel, rightLevel: player.rightLevel, orientation: .horizontal)
                    .frame(height: 20)
            }
            
            // VU Meter Sensitivity slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sensibilidad VU")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", player.vuMeterSensitivity))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    Text("Baja")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { player.vuMeterSensitivity },
                        set: { player.vuMeterSensitivity = $0 }
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
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func effectsSection(player: MusicPlayer, title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Reverb
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Reverb", isOn: Binding(
                        get: { player.reverbEnabled },
                        set: { player.reverbEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.reverbEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Wet/Dry Mix")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(player.reverbWetDryMix))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.reverbWetDryMix },
                            set: { player.reverbWetDryMix = $0 }
                        ), in: 0...100)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Delay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Delay", isOn: Binding(
                        get: { player.delayEnabled },
                        set: { player.delayEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.delayEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Tiempo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2fs", player.delayTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(player.delayTime) },
                            set: { player.delayTime = TimeInterval($0) }
                        ), in: 0...2.0)
                        
                        HStack {
                            Text("Feedback")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(player.delayFeedback))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.delayFeedback },
                            set: { player.delayFeedback = $0 }
                        ), in: 0...100)
                        
                        HStack {
                            Text("Wet/Dry Mix")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(player.delayWetDryMix))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.delayWetDryMix },
                            set: { player.delayWetDryMix = $0 }
                        ), in: 0...100)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Equalizer
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Equalizer", isOn: Binding(
                        get: { player.equalizerEnabled },
                        set: { player.equalizerEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.equalizerEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Bajos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f dB", player.equalizerLowGain))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.equalizerLowGain },
                            set: { player.equalizerLowGain = $0 }
                        ), in: -12...12)
                        
                        HStack {
                            Text("Medios")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f dB", player.equalizerMidGain))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.equalizerMidGain },
                            set: { player.equalizerMidGain = $0 }
                        ), in: -12...12)
                        
                        HStack {
                            Text("Agudos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f dB", player.equalizerHighGain))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { player.equalizerHighGain },
                            set: { player.equalizerHighGain = $0 }
                        ), in: -12...12)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
    
    private func applyMasterVolume() {
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
