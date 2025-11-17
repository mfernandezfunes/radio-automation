//
//  AudioOutputView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI
import AppKit

struct AudioOutputView: View {
    @ObservedObject var player1: MusicPlayer
    @ObservedObject var player2: MusicPlayer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title
                Text("Salida de Audio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                // Audio Chain Visualization - Top section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cadena de Audio Global")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Global audio chain visualization with merge
                    VStack(spacing: 12) {
                        // Inputs row - both players
                        HStack(spacing: 40) {
                            // Player 1 Input
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "music.note")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Player 1")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if player1.isPlaying {
                                    Text("ON AIR")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .frame(width: 80)
                            
                            // Player 2 Input
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Circle()
                                        .stroke(Color.green, lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "music.note")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                }
                                
                                Text("Player 2")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if player2.isPlaying {
                                    Text("ON AIR")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .frame(width: 80)
                        }
                        
                        // Merge visualization - diagonal lines converging
                        HStack(spacing: 40) {
                            // Player 1 arrow (diagonal down-right)
                            VStack(spacing: 0) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .frame(width: 80)
                            }
                            
                            // Player 2 arrow (diagonal down-left)
                            VStack(spacing: 0) {
                                Image(systemName: "arrow.down.left")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                    .frame(width: 80)
                            }
                        }
                        .frame(height: 30)
                        
                        // Processing chain row (centered)
                        HStack(spacing: 8) {
                            // Global Mixer
                            GlobalEffectNode(
                                icon: "slider.horizontal.below.rectangle",
                                label: "Mixer Global",
                                isActive: true,
                                color: .gray
                            )
                            
                            GlobalArrow()
                            
                            // Output Equalizer (clickeable)
                            Button(action: {
                                GlobalAudioMixer.shared.outputEqualizerEnabled.toggle()
                            }) {
                                GlobalEffectNode(
                                    icon: "slider.horizontal.3",
                                    label: "EQ Salida",
                                    isActive: GlobalAudioMixer.shared.outputEqualizerEnabled,
                                    color: .red,
                                    intensity: GlobalAudioMixer.shared.outputEqualizerEnabled ? 1.0 : 0.0
                                )
                            }
                            .buttonStyle(.plain)
                            .help("Clic para activar/desactivar el equalizador de salida")
                            
                            GlobalArrow()
                            
                            // Final Output
                            GlobalEffectNode(
                                icon: "speaker.wave.3.fill",
                                label: "Salida",
                                isActive: true,
                                color: .blue
                            )
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                
                // Master Volume
                VStack(alignment: .leading, spacing: 12) {
                    Text("Volumen Master")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Slider(value: Binding(
                            get: { GlobalAudioMixer.shared.outputVolume },
                            set: { GlobalAudioMixer.shared.outputVolume = $0 }
                        ), in: 0...1) {
                            Text("Volumen Master")
                        }
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Text("\(Int(GlobalAudioMixer.shared.outputVolume * 100))%")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 50, alignment: .trailing)
                            .monospacedDigit()
                    }
                    
                    // Global VU Meter
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nivel de Salida")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VUMeterView(
                            leftLevel: GlobalAudioMixer.shared.leftLevel,
                            rightLevel: GlobalAudioMixer.shared.rightLevel,
                            orientation: .horizontal
                        )
                        .frame(height: 20)
                    }
                    
                    Text("Controla el volumen master de la salida final de audio (afecta a ambos players)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Stereo Balance
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Balance Estéreo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(GlobalAudioMixer.shared.stereoBalance == 0 ? "Centro" : GlobalAudioMixer.shared.stereoBalance > 0 ? "Derecha \(String(format: "%.0f%%", abs(GlobalAudioMixer.shared.stereoBalance) * 100))" : "Izquierda \(String(format: "%.0f%%", abs(GlobalAudioMixer.shared.stereoBalance) * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Slider(value: Binding(
                            get: { GlobalAudioMixer.shared.stereoBalance },
                            set: { GlobalAudioMixer.shared.stereoBalance = $0 }
                        ), in: -1.0...1.0) {
                            Text("Balance Estéreo")
                        }
                        
                        Image(systemName: "speaker.wave.1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                    }
                    
                    // Quick balance buttons
                    HStack(spacing: 8) {
                        Button("Izq") {
                            GlobalAudioMixer.shared.stereoBalance = -1.0
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Centro") {
                            GlobalAudioMixer.shared.stereoBalance = 0.0
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Der") {
                            GlobalAudioMixer.shared.stereoBalance = 1.0
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                    }
                    
                    Text("Controla el balance estéreo de la salida final (afecta a ambos players)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Output Equalizer - Only show sliders if enabled
                if GlobalAudioMixer.shared.outputEqualizerEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Equalizador de Salida")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Status indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Activo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Este equalizador se aplica a la salida final de audio, afectando a ambos players simultáneamente.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            // Low frequency (Bass)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Bajos (80 Hz)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f dB", GlobalAudioMixer.shared.outputEqualizerLowGain))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: Binding(
                                    get: { GlobalAudioMixer.shared.outputEqualizerLowGain },
                                    set: { GlobalAudioMixer.shared.outputEqualizerLowGain = $0 }
                                ), in: -12...12)
                            }
                            
                            // Mid frequency
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Medios (1 kHz)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f dB", GlobalAudioMixer.shared.outputEqualizerMidGain))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: Binding(
                                    get: { GlobalAudioMixer.shared.outputEqualizerMidGain },
                                    set: { GlobalAudioMixer.shared.outputEqualizerMidGain = $0 }
                                ), in: -12...12)
                            }
                            
                            // High frequency (Treble)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Agudos (8 kHz)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f dB", GlobalAudioMixer.shared.outputEqualizerHighGain))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: Binding(
                                    get: { GlobalAudioMixer.shared.outputEqualizerHighGain },
                                    set: { GlobalAudioMixer.shared.outputEqualizerHighGain = $0 }
                                ), in: -12...12)
                            }
                            
                            // Reset button
                            Button(action: {
                                GlobalAudioMixer.shared.outputEqualizerLowGain = 0.0
                                GlobalAudioMixer.shared.outputEqualizerMidGain = 0.0
                                GlobalAudioMixer.shared.outputEqualizerHighGain = 0.0
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Resetear a 0 dB")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // AirPlay Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "airplayaudio")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("AirPlay")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Salida de Audio")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Selecciona AirPlay desde Preferencias del Sistema → Sonido")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Open System Preferences to Sound settings
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Abrir Preferencias del Sistema")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Audio Output Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Información de Salida")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dispositivo de Salida:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Sistema macOS")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("Para cambiar el dispositivo de salida (Bluetooth, etc.), usa Preferencias del Sistema → Sonido")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
        .frame(width: 550, height: 650)
    }
}

#Preview {
    let playlist1 = Playlist()
    let player1 = MusicPlayer(playlist: playlist1, playerName: "Player 1")
    let playlist2 = Playlist()
    let player2 = MusicPlayer(playlist: playlist2, playerName: "Player 2")
    
    return AudioOutputView(player1: player1, player2: player2)
}

// Helper components for global audio chain visualization
private struct GlobalEffectNode: View {
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

private struct GlobalArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(width: 16)
    }
}

