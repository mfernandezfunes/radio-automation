//
//  ConfigView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI
import AVFoundation

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
                
                // Playback Controls side by side
                HStack(alignment: .top, spacing: 20) {
                    // Playback Controls for Player 1
                    playbackControlsSection(player: player1, title: "Controles de Reproducción - Player 1")
                    
                    // Playback Controls for Player 2
                    playbackControlsSection(player: player2, title: "Controles de Reproducción - Player 2")
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
            
            Divider()
                .padding(.vertical, 8)
            
            // BPM Detection Parameters
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Detección de BPM")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: {
                        // Re-analyze BPM if a song is loaded
                        if let song = player.playlist.currentSong,
                           let url = song.accessibleURL() {
                            url.startAccessingSecurityScopedResource()
                            defer { url.stopAccessingSecurityScopedResource() }
                            
                            if let file = try? AVAudioFile(forReading: url) {
                                player.analyzeBPM(for: file)
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Re-analizar")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(player.playlist.currentSong == nil)
                }
                
                // BPM Detection Threshold
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Umbral de Detección")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", player.bpmDetectionThreshold))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        Text("0.1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player.bpmDetectionThreshold },
                            set: { player.bpmDetectionThreshold = $0 }
                        ), in: 0.1...1.0)
                        
                        Text("1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                // BPM Range
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rango de BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mínimo")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("\(Int(player.bpmMinBPM))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 40)
                                Slider(value: Binding(
                                    get: { player.bpmMinBPM },
                                    set: { player.bpmMinBPM = $0 }
                                ), in: 20...150)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Máximo")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("\(Int(player.bpmMaxBPM))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 40)
                                Slider(value: Binding(
                                    get: { player.bpmMaxBPM },
                                    set: { player.bpmMaxBPM = $0 }
                                ), in: 150...400)
                            }
                        }
                    }
                }
                
                // Smoothing Window
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Ventana de Suavizado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(player.bpmSmoothingWindow)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        Text("1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { Double(player.bpmSmoothingWindow) },
                            set: { player.bpmSmoothingWindow = Int($0) }
                        ), in: 1...20)
                        
                        Text("20")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            Divider()
                .padding(.vertical, 8)
            
            // Real-time Beat Detection Parameters
            VStack(alignment: .leading, spacing: 12) {
                Text("Detección de Beats en Tiempo Real")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Smoothing Factor
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Factor de Suavizado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", player.beatSmoothingFactor))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        Text("0.5")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player.beatSmoothingFactor },
                            set: { player.beatSmoothingFactor = $0 }
                        ), in: 0.5...0.99)
                        
                        Text("0.99")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                // Min Relative Increase
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Aumento Relativo Mínimo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", player.beatMinRelativeIncrease * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        Text("5%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player.beatMinRelativeIncrease },
                            set: { player.beatMinRelativeIncrease = $0 }
                        ), in: 0.05...0.5)
                        
                        Text("50%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                // Std Dev Multiplier
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Multiplicador Desviación Estándar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", player.beatStdDevMultiplier))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        Text("0.5")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { player.beatStdDevMultiplier },
                            set: { player.beatStdDevMultiplier = $0 }
                        ), in: 0.5...3.0)
                        
                        Text("3.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
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
    
    @ViewBuilder
    private func playbackControlsSection(player: MusicPlayer, title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Playback Speed
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Velocidad de Reproducción")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.2fx", player.playbackRate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 12) {
                    Text("0.5x")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { player.playbackRate },
                        set: { player.playbackRate = $0 }
                    ), in: 0.5...2.0)
                    
                    Text("2.0x")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                // Quick speed buttons
                HStack(spacing: 8) {
                    Button("0.75x") {
                        player.playbackRate = 0.75
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("1.0x") {
                        player.playbackRate = 1.0
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("1.25x") {
                        player.playbackRate = 1.25
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("1.5x") {
                        player.playbackRate = 1.5
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Stereo Balance
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Balance Estéreo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(player.stereoBalance == 0 ? "Centro" : player.stereoBalance > 0 ? "Derecha \(String(format: "%.0f%%", abs(player.stereoBalance) * 100))" : "Izquierda \(String(format: "%.0f%%", abs(player.stereoBalance) * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { player.stereoBalance },
                        set: { player.stereoBalance = $0 }
                    ), in: -1.0...1.0)
                    
                    Image(systemName: "speaker.wave.1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                
                // Quick balance buttons
                HStack(spacing: 8) {
                    Button("Izq") {
                        player.stereoBalance = -1.0
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Centro") {
                        player.stereoBalance = 0.0
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Der") {
                        player.stereoBalance = 1.0
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Crossfade
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Crossfade", isOn: Binding(
                        get: { player.crossfadeEnabled },
                        set: { player.crossfadeEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.crossfadeEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Duración")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f s", player.crossfadeDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { player.crossfadeDuration },
                            set: { player.crossfadeDuration = $0 }
                        ), in: 1.0...15.0)
                        
                        // Quick duration buttons
                        HStack(spacing: 8) {
                            Button("3s") {
                                player.crossfadeDuration = 3.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("5s") {
                                player.crossfadeDuration = 5.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("10s") {
                                player.crossfadeDuration = 10.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Fade In
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Fade In", isOn: Binding(
                        get: { player.fadeInEnabled },
                        set: { player.fadeInEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.fadeInEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Duración")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f s", player.fadeInDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { player.fadeInDuration },
                            set: { player.fadeInDuration = $0 }
                        ), in: 0.5...10.0)
                        
                        // Quick duration buttons
                        HStack(spacing: 8) {
                            Button("1s") {
                                player.fadeInDuration = 1.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("2s") {
                                player.fadeInDuration = 2.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("5s") {
                                player.fadeInDuration = 5.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            
            // Fade Out
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Fade Out", isOn: Binding(
                        get: { player.fadeOutEnabled },
                        set: { player.fadeOutEnabled = $0 }
                    ))
                    Spacer()
                }
                
                if player.fadeOutEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Duración")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f s", player.fadeOutDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { player.fadeOutDuration },
                            set: { player.fadeOutDuration = $0 }
                        ), in: 0.5...10.0)
                        
                        // Quick duration buttons
                        HStack(spacing: 8) {
                            Button("1s") {
                                player.fadeOutDuration = 1.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("2s") {
                                player.fadeOutDuration = 2.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("5s") {
                                player.fadeOutDuration = 5.0
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
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
