//
//  PlayerView.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Combine

struct PlayerView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var player: MusicPlayer
    @State private var showingFilePicker = false
    @State private var blinkOpacity: Double = 1.0
    @State private var blinkTimer: Timer?
    @State private var sliderValue: Double = 0
    @State private var isDraggingSlider: Bool = false
    @State private var seekTimer: Timer?
    
    let playerName: String
    
    // Computed property to check if next song should blink
    private var shouldBlinkNextSong: Bool {
        guard player.isPlaying,
              let currentIndex = playlist.currentIndex,
              player.duration > 0 else {
            return false
        }
        
        let timeRemaining = player.duration - player.currentTime
        return timeRemaining <= 10.0 && playlist.getNextIndex() != nil
    }
    
    init(playerName: String, playlist: Playlist, player: MusicPlayer) {
        self.playerName = playerName
        self.playlist = playlist
        self.player = player
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
                    
                    // Shuffle, Repeat, and Auto-play controls
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
            .background(Color(NSColor.controlBackgroundColor))
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
            .background(Color(NSColor.controlBackgroundColor))
            
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
                    ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
                        let isNextSong = playlist.getNextIndex() == index
                        let shouldBlink = shouldBlinkNextSong && isNextSong
                        
                        HStack {
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
                                    } else if isNextSong {
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
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(action: {
                                // Stop current playback and play this song now
                                // loadCurrentSong() already calls stop() internally
                                playlist.currentIndex = index
                                player.loadCurrentSong()
                                // Wait a moment for the file to load before playing
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
                            
                            if index > 0 {
                                Button(action: {
                                    // Move song up one position
                                    playlist.moveSong(from: IndexSet(integer: index), to: index - 1)
                                }) {
                                    Label("Subir uno en la lista", systemImage: "arrow.up")
                                }
                            }
                            
                            if index < playlist.songs.count - 1 {
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

