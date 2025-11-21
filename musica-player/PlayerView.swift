//
//  PlayerView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import CoreMedia
import Combine

struct PlayerView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var player: MusicPlayer
    var otherPlayer: MusicPlayer? // Reference to the other player for commands
    @State private var showingFilePicker = false
    @State private var blinkOpacity: Double = 1.0
    @State private var blinkTimer: Timer?
    @State private var sliderValue: Double = 0
    @State private var isDraggingSlider: Bool = false
    @State private var seekTimer: Timer?
    @State private var durationCache: [UUID: TimeInterval] = [:]
    
    let playerName: String
    
    // Computed property to check if next song should blink
    private var shouldBlinkNextSong: Bool {
        guard player.isPlaying,
              playlist.currentIndex != nil,
              player.duration > 0 else {
            return false
        }
        
        let timeRemaining = player.duration - player.currentTime
        return timeRemaining <= 10.0 && playlist.getNextIndex() != nil
    }
    
    init(playerName: String, playlist: Playlist, player: MusicPlayer, otherPlayer: MusicPlayer? = nil) {
        self.playerName = playerName
        self.playlist = playlist
        self.player = player
        self.otherPlayer = otherPlayer
    }
    
    // Helper function to format time
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Get cached duration or nil if not cached yet
    private func getCachedDuration(for song: Song) -> TimeInterval? {
        return durationCache[song.id]
    }
    
    // Load duration asynchronously and cache it
    private func loadDuration(for song: Song) {
        // Don't reload if already cached
        guard durationCache[song.id] == nil else { return }
        
        let songId = song.id
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let accessibleURL = song.accessibleURL() else { return }
            
            // Ensure we have access to the file
            let hasAccess = accessibleURL.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    accessibleURL.stopAccessingSecurityScopedResource()
                }
            }
            
            var duration: TimeInterval?
            
            // Try using AVAudioFile first (more reliable for audio files)
            do {
                let audioFile = try AVAudioFile(forReading: accessibleURL)
                let format = audioFile.processingFormat
                let frameCount = Double(audioFile.length)
                let sampleRate = format.sampleRate
                let calculatedDuration = frameCount / sampleRate
                if calculatedDuration.isFinite && calculatedDuration > 0 {
                    duration = calculatedDuration
                }
            } catch {
                // Fallback to AVAsset if AVAudioFile fails
                let asset = AVAsset(url: accessibleURL)
                let assetDuration = asset.duration
                let durationSeconds = CMTimeGetSeconds(assetDuration)
                if durationSeconds.isFinite && durationSeconds > 0 {
                    duration = durationSeconds
                }
            }
            
            // Update cache on main thread
            if let duration = duration {
                DispatchQueue.main.async { [self] in
                    self.durationCache[songId] = duration
                }
            }
        }
    }
    
    // Helper function to extract metadata from audio file
    private func extractMetadata(from url: URL) -> (title: String, artist: String) {
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown artist"
        
        let asset = AVAsset(url: url)
        
        // Try to read common metadata keys first (fastest method)
        let commonMetadata = asset.metadata
        
        for item in commonMetadata {
            guard let key = item.commonKey else { continue }
            
            switch key {
            case .commonKeyTitle:
                if let value = item.value as? String, !value.isEmpty {
                    title = value
                }
            case .commonKeyArtist:
                if let value = item.value as? String, !value.isEmpty {
                    artist = value
                }
            case .commonKeyAlbumName:
                // Could be used for album display in the future
                break
            default:
                break
            }
        }
        
        // If we didn't find metadata in common keys, try format-specific metadata
        if title == url.deletingPathExtension().lastPathComponent || artist == "Unknown artist" {
            for format in asset.availableMetadataFormats {
                let formatMetadata = asset.metadata(forFormat: format)
                
                for item in formatMetadata {
                    // Try common key first
                    if let key = item.commonKey {
                        switch key {
                        case .commonKeyTitle:
                            if let value = item.value as? String, !value.isEmpty, title == url.deletingPathExtension().lastPathComponent {
                                title = value
                            }
                        case .commonKeyArtist:
                            if let value = item.value as? String, !value.isEmpty, artist == "Unknown artist" {
                                artist = value
                            }
                        default:
                            break
                        }
                    }
                    
                    // Try identifier-based lookup (for ID3 tags, etc.)
                    if let identifier = item.identifier {
                        let identifierString = identifier.rawValue.lowercased()
                        
                        // ID3 tags
                        if identifierString.contains("tit2") || identifierString.contains("title") {
                            if let value = item.value as? String, !value.isEmpty, title == url.deletingPathExtension().lastPathComponent {
                                title = value
                            }
                        } else if identifierString.contains("tpe1") || identifierString.contains("artist") {
                            if let value = item.value as? String, !value.isEmpty, artist == "Unknown artist" {
                                artist = value
                            }
                        }
                    }
                }
            }
        }
        
        return (title: title, artist: artist)
    }
    
    private func updateBlinkState() {
        let shouldBlink = shouldBlinkNextSong
        
        if shouldBlink {
            // Only start blinking if not already blinking
            if blinkTimer == nil {
                startBlinking()
            }
        } else {
            stopBlinking()
        }
    }
    
    private func startBlinking() {
        // Stop any existing timer first
        stopBlinking()
        
        // Start blinking animation
        // Timer.scheduledTimer already runs on main thread
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                blinkOpacity = blinkOpacity == 1.0 ? 0.3 : 1.0
            }
        }
    }
    
    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        blinkOpacity = 1.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Player controls - fixed size
            VStack(spacing: 12) {
                // Current song info - large and prominent
                if let currentSong = playlist.currentSong {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentSong.title)
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(currentSong.artist)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Next song info - show when a song is marked as next
                if let nextIndex = playlist.nextIndex,
                   nextIndex >= 0 && nextIndex < playlist.items.count {
                    let nextItem = playlist.items[nextIndex]
                    if !nextItem.isCommand, let nextSong = nextItem.song {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("NEXT:")
                                .font(.system(size: 12, weight: .bold, design: .default))
                                .foregroundColor(.orange)
                            Text(nextSong.title)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if let nextDuration = player.nextSongDuration {
                                Text("• \(formatTime(nextDuration))")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundColor(.orange)
                            }
                        }
                        Text(nextSong.artist)
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
                    .padding(.horizontal)
                    }
                }
                
                // Advanced playback controls
                VStack(spacing: 12) {
                    // Main playback controls with VU meters
                    HStack(spacing: 20) {
                        // Playback controls
                        HStack(spacing: 20) {
                            Button(action: {
                                player.rewind()
                            }) {
                                Image(systemName: "gobackward.10")
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty || player.duration == 0)
                            
                            Button(action: {
                                player.previous()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty)
                            
                            Button(action: {
                                player.stop()
                            }) {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty)
                            
                            Button(action: {
                                player.togglePlayPause()
                            }) {
                                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 48))
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty)
                            
                            Button(action: {
                                player.next()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty)
                            
                            Button(action: {
                                player.fastForward()
                            }) {
                                Image(systemName: "goforward.10")
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .disabled(playlist.songs.isEmpty || player.duration == 0)
                        }
                        .padding(.vertical, 8)
                        
                        Spacer()
                        
                        // VU Meters - always visible on the right
                        VUMeterView(leftLevel: player.leftLevel, rightLevel: player.rightLevel)
                            .frame(height: 120)
                    }
                    .padding(.vertical, 8)
                    
                    // Shuffle, Repeat, Auto-play, and Crossfade controls
                    HStack(spacing: 30) {
                        Button(action: {
                            playlist.toggleShuffle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "shuffle")
                                    .font(.body)
                                if playlist.isShuffled {
                                    Text("ON")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(playlist.isShuffled ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(playlist.songs.isEmpty)
                        
                        Button(action: {
                            playlist.toggleRepeat()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: playlist.repeatMode == .one ? "repeat.1" : "repeat")
                                    .font(.body)
                                if playlist.repeatMode != .off {
                                    Text(playlist.repeatMode == .one ? "ONE" : "ALL")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(playlist.repeatMode != .off ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(playlist.songs.isEmpty)
                        
                        Button(action: {
                            player.autoPlayNext.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.body)
                                if player.autoPlayNext {
                                    Text("AUTO")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(player.autoPlayNext ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(playlist.songs.isEmpty)
                        
                        Button(action: {
                            player.crossfadeEnabled.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform.path")
                                    .font(.body)
                                if player.crossfadeEnabled {
                                    Text("XFADE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(player.crossfadeEnabled ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(playlist.songs.isEmpty)
                        .help("Crossfade: funde automáticamente entre canciones (\(String(format: "%.1f", player.crossfadeDuration))s)")
                    }
                    
                    // Progress bar - moved below controls
                    if player.duration > 0 {
                        VStack(spacing: 4) {
                            Slider(
                                value: Binding(
                                    get: { isDraggingSlider ? sliderValue : player.currentTime },
                                    set: { newValue in
                                        sliderValue = newValue
                                        if !isDraggingSlider {
                                            isDraggingSlider = true
                                        }
                                        
                                        // Cancel previous seek timer
                                        seekTimer?.invalidate()
                                        
                                        // Schedule seek after user stops dragging (debounce)
                                        let timerValue = sliderValue
                                        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in
                                            isDraggingSlider = false
                                            player.seek(to: timerValue)
                                            timer.invalidate()
                                        }
                                        RunLoop.current.add(seekTimer!, forMode: .common)
                                    }
                                ),
                                in: 0...player.duration
                            )
                            HStack {
                                Text(player.formatTime(isDraggingSlider ? sliderValue : player.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(player.formatTime(player.duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let bpm = player.detectedBPM {
                                    Text("• \(Int(bpm)) BPM")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                                if let key = player.detectedKey {
                                    Text("• \(key)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                                // Beat indicator LED - more visible
                                Circle()
                                    .fill(player.beatDetected ? Color.red : Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(player.beatDetected ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
                                            .scaleEffect(player.beatDetected ? 1.5 : 1.0)
                                    )
                                    .padding(.leading, 8)
                                    .animation(.easeOut(duration: 0.1), value: player.beatDetected)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Volume control
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $player.volume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding()
            .background(.thinMaterial)
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Header for playlist with add button
            HStack {
                Text("Playlist")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    showingFilePicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            
            // Song list - takes all available space
            if playlist.songs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No songs")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add songs")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(playlist.items) { item in
                        let index = playlist.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        let isNextItem = playlist.getNextIndex() == index
                        let shouldBlink = shouldBlinkNextSong && isNextItem
                        
                        if item.isCommand, let command = item.command {
                            // Display command item
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Image(systemName: command.commandType.icon)
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(command.commandType.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        if isNextItem {
                                            Text("NEXT")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text("Comando")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("--")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                                
                                if playlist.currentIndex == index {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(shouldBlink ? blinkOpacity : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: blinkOpacity)
                            .background(
                                playlist.currentIndex == index
                                    ? Color.blue.opacity(0.15)
                                    : Color.blue.opacity(0.05)
                            )
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(action: {
                                    // Stop current playback and execute this command now
                                    player.stop()
                                    playlist.currentIndex = index
                                    if let currentItem = playlist.currentItem, currentItem.isCommand {
                                        player.executeCommand(currentItem.command!)
                                    }
                                }) {
                                    Label("Parar y Ejecutar Ahora", systemImage: "play.fill")
                                }
                                
                                Button(action: {
                                    // Set as next item
                                    playlist.setNextIndex(index)
                                }) {
                                    Label("Reproducir Siguiente", systemImage: "forward.fill")
                                }
                                
                                Divider()
                                
                                // Insert command options
                                Menu("Insertar Comando") {
                                    if let otherPlayer = otherPlayer {
                                        // Show command based on current player
                                        if playerName == "Player 1" {
                                            Button(action: {
                                                let newCommand = PlaylistCommand(commandType: .stopPlayer1AndPlayNextInPlayer2)
                                                playlist.addCommand(newCommand, afterIndex: index)
                                            }) {
                                                Label("Parar Player 1 → Siguiente en Player 2", systemImage: "arrow.triangle.2.circlepath")
                                            }
                                        } else if playerName == "Player 2" {
                                            Button(action: {
                                                let newCommand = PlaylistCommand(commandType: .stopPlayer2AndPlayNextInPlayer1)
                                                playlist.addCommand(newCommand, afterIndex: index)
                                            }) {
                                                Label("Parar Player 2 → Siguiente en Player 1", systemImage: "arrow.triangle.2.circlepath")
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            let newCommand = PlaylistCommand(commandType: .stopPlayer1)
                                            playlist.addCommand(newCommand, afterIndex: index)
                                        }) {
                                            Label("Parar Player 1", systemImage: "stop.fill")
                                        }
                                        
                                        Button(action: {
                                            let newCommand = PlaylistCommand(commandType: .stopPlayer2)
                                            playlist.addCommand(newCommand, afterIndex: index)
                                        }) {
                                            Label("Parar Player 2", systemImage: "stop.fill")
                                        }
                                        
                                        Button(action: {
                                            let newCommand = PlaylistCommand(commandType: .pausePlayer1)
                                            playlist.addCommand(newCommand, afterIndex: index)
                                        }) {
                                            Label("Pausar Player 1", systemImage: "pause.fill")
                                        }
                                        
                                        Button(action: {
                                            let newCommand = PlaylistCommand(commandType: .pausePlayer2)
                                            playlist.addCommand(newCommand, afterIndex: index)
                                        }) {
                                            Label("Pausar Player 2", systemImage: "pause.fill")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                if index > 0 {
                                    Button(action: {
                                        // Move command up one position
                                        playlist.moveSong(from: IndexSet(integer: index), to: index - 1)
                                    }) {
                                        Label("Subir uno en la lista", systemImage: "arrow.up")
                                    }
                                }
                                
                                if index < playlist.items.count - 1 {
                                    Button(action: {
                                        // Move command down one position
                                        playlist.moveSong(from: IndexSet(integer: index), to: index + 2)
                                    }) {
                                        Label("Bajar uno en la lista", systemImage: "arrow.down")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    // Remove command from playlist
                                    playlist.removeSong(at: index)
                                }) {
                                    Label("Eliminar de la lista", systemImage: "trash")
                                }
                            }
                        } else if let song = item.song {
                            // Display song item
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(song.title)
                                            .font(.body)
                                            .fontWeight(playlist.currentIndex == index ? .semibold : .regular)
                                            .foregroundColor(.primary)
                                        
                                        if playlist.currentIndex == index && player.isPlaying {
                                            Text("ON AIR")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2))
                                                .cornerRadius(4)
                                        } else if isNextItem {
                                            Text("NEXT")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(song.artist)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // Show duration
                                Group {
                                    // If this is the next song and we have preloaded duration, use it
                                    if isNextItem, let nextDuration = player.nextSongDuration {
                                        Text(formatTime(nextDuration))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.orange)
                                            .frame(width: 50, alignment: .trailing)
                                    } else if let duration = getCachedDuration(for: song) {
                                        Text(formatTime(duration))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 50, alignment: .trailing)
                                    } else {
                                        Text("--:--")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 50, alignment: .trailing)
                                            .onAppear {
                                                loadDuration(for: song)
                                            }
                                    }
                                }
                                
                                if playlist.currentIndex == index {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(shouldBlink ? blinkOpacity : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: blinkOpacity)
                            .background(
                                playlist.currentIndex == index
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.clear
                            )
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(action: {
                                    // Stop current playback and play this song now
                                    playlist.currentIndex = index
                                    player.loadCurrentSong()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        player.play()
                                    }
                                }) {
                                    Label("Parar y Reproducir Ahora", systemImage: "play.fill")
                                }
                                
                                Button(action: {
                                    // Set as next song
                                    playlist.setNextIndex(index)
                                }) {
                                    Label("Reproducir Siguiente", systemImage: "forward.fill")
                                }
                                
                                Divider()
                                
                                // Insert command options
                                Menu("Insertar Comando") {
                                    if let otherPlayer = otherPlayer {
                                        // Show command based on current player
                                        if playerName == "Player 1" {
                                            Button(action: {
                                                let command = PlaylistCommand(commandType: .stopPlayer1AndPlayNextInPlayer2)
                                                playlist.addCommand(command, afterIndex: index)
                                            }) {
                                                Label("Parar Player 1 → Siguiente en Player 2", systemImage: "arrow.triangle.2.circlepath")
                                            }
                                        } else if playerName == "Player 2" {
                                            Button(action: {
                                                let command = PlaylistCommand(commandType: .stopPlayer2AndPlayNextInPlayer1)
                                                playlist.addCommand(command, afterIndex: index)
                                            }) {
                                                Label("Parar Player 2 → Siguiente en Player 1", systemImage: "arrow.triangle.2.circlepath")
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            let command = PlaylistCommand(commandType: .stopPlayer1)
                                            playlist.addCommand(command, afterIndex: index)
                                        }) {
                                            Label("Parar Player 1", systemImage: "stop.fill")
                                        }
                                        
                                        Button(action: {
                                            let command = PlaylistCommand(commandType: .stopPlayer2)
                                            playlist.addCommand(command, afterIndex: index)
                                        }) {
                                            Label("Parar Player 2", systemImage: "stop.fill")
                                        }
                                        
                                        Button(action: {
                                            let command = PlaylistCommand(commandType: .pausePlayer1)
                                            playlist.addCommand(command, afterIndex: index)
                                        }) {
                                            Label("Pausar Player 1", systemImage: "pause.fill")
                                        }
                                        
                                        Button(action: {
                                            let command = PlaylistCommand(commandType: .pausePlayer2)
                                            playlist.addCommand(command, afterIndex: index)
                                        }) {
                                            Label("Pausar Player 2", systemImage: "pause.fill")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                if index > 0 {
                                    Button(action: {
                                        // Move song up one position
                                        playlist.moveSong(from: IndexSet(integer: index), to: index - 1)
                                    }) {
                                        Label("Subir uno en la lista", systemImage: "arrow.up")
                                    }
                                }
                                
                                if index < playlist.items.count - 1 {
                                    Button(action: {
                                        // Move song down one position
                                        playlist.moveSong(from: IndexSet(integer: index), to: index + 2)
                                    }) {
                                        Label("Bajar uno en la lista", systemImage: "arrow.down")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    // Remove song from playlist
                                    playlist.removeSong(at: index)
                                }) {
                                    Label("Eliminar de la lista", systemImage: "trash")
                                }
                            }
                            .onTapGesture(count: 2) {
                                // Mark this song as next to play
                                playlist.setNextIndex(index)
                                // If no song is currently playing, start playing this one
                                if playlist.currentIndex == nil || !player.isPlaying {
                                    playlist.currentIndex = index
                                    player.loadCurrentSong()
                                    player.play()
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        playlist.removeSong(at: indexSet.first ?? 0)
                    }
                    .onMove { source, destination in
                        playlist.moveSong(from: source, to: destination)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 500, minHeight: 700)
        .onChange(of: player.currentTime) { newTime in
            // Update slider value when not dragging
            if !isDraggingSlider {
                sliderValue = newTime
            }
            // Update blink state
            updateBlinkState()
        }
        .onChange(of: player.isPlaying) { isPlaying in
            if !isPlaying {
                stopBlinking()
            } else {
                updateBlinkState()
            }
        }
        .onChange(of: playlist.currentIndex) { _ in
            updateBlinkState()
        }
        .onDisappear {
            stopBlinking()
            seekTimer?.invalidate()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [
                .audio,
                UTType(filenameExtension: "mp3")!,
                UTType(filenameExtension: "m4a")!,
                UTType(filenameExtension: "aac")!,
                UTType(filenameExtension: "wav")!,
                UTType(filenameExtension: "flac")!
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    // Access file securely
                    guard url.startAccessingSecurityScopedResource() else {
                        continue
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // Create security bookmark for future access
                    let bookmark = try? url.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    
                    // Extract metadata from audio file
                    let metadata = extractMetadata(from: url)
                    
                    let song = Song(
                        title: metadata.title,
                        artist: metadata.artist,
                        url: url,
                        securityScopedBookmark: bookmark
                    )
                    playlist.addSong(song)
                }
            case .failure(let error):
                print("Error selecting files: \(error)")
            }
        }
    }
}

#Preview {
    let playlist = Playlist()
    let player = MusicPlayer(playlist: playlist)
    return PlayerView(playerName: "Player 1", playlist: playlist, player: player)
        .frame(width: 500, height: 700)
}
