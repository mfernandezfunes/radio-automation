//
//  MusicPlayer.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation
import AVFoundation
import Combine

class MusicPlayer: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.5 {
        didSet {
            player?.volume = volume
        }
    }
    
    @Published var autoPlayNext: Bool = false // Auto-continue to next song when current finishes
    
    private let seekInterval: TimeInterval = 10.0 // 10 seconds for rewind/fast forward
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var currentAccessingURL: URL?
    
    var playlist: Playlist
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init()
        
        // Observe playlist changes
        playlist.$currentIndex
            .sink { [weak self] _ in
                self?.loadCurrentSong()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        
        // Release file access when destroying the player
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    func loadCurrentSong() {
        guard let song = playlist.currentSong else {
            stop()
            return
        }
        
        // Stop current player and release previous access
        stop()
        
        // Release previous access if it exists
        if let previousURL = currentAccessingURL {
            previousURL.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
        
        // Get accessible URL using security bookmark
        guard let accessibleURL = song.accessibleURL() else {
            print("Could not access audio file")
            return
        }
        
        // Access resource securely and maintain access while player is active
        guard accessibleURL.startAccessingSecurityScopedResource() else {
            print("Could not obtain access to audio file")
            return
        }
        
        currentAccessingURL = accessibleURL
        
        // Create new player with the song
        let playerItem = AVPlayerItem(url: accessibleURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        // Observe when song finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Observe duration
        playerItem.publisher(for: \.duration)
            .sink { [weak self] duration in
                if duration.isValid && !duration.isIndefinite {
                    self?.duration = duration.seconds
                }
            }
            .store(in: &cancellables)
        
        // Observe current time
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    func play() {
        if playlist.currentSong == nil {
            // If no current song, play the first one
            if !playlist.songs.isEmpty {
                playlist.currentIndex = 0
                loadCurrentSong()
            } else {
                return
            }
        }
        
        if player == nil {
            loadCurrentSong()
        }
        
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        
        // Release file access when stopped
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func next() {
        // Stop current playback
        stop()
        
        // Load and play next song
        if let nextSong = playlist.nextSong() {
            loadCurrentSong()
            play()
        }
    }
    
    func previous() {
        // Stop current playback
        stop()
        
        // Load and play previous song
        if let previousSong = playlist.previousSong() {
            loadCurrentSong()
            play()
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        // Handle repeat mode
        if playlist.repeatMode == .one {
            // Repeat current song
            loadCurrentSong()
            play()
        } else if autoPlayNext {
            // Automatically play next song if auto-play is enabled
            // Continue playing even if isPlaying was false
            if let nextSong = playlist.nextSong() {
                loadCurrentSong()
                play() // Always play when auto-play is enabled
            } else {
                stop()
            }
        } else {
            // Stop playback if auto-play is disabled
            stop()
        }
    }
    
    func rewind() {
        let newTime = max(0, currentTime - seekInterval)
        seek(to: newTime)
    }
    
    func fastForward() {
        let newTime = min(duration, currentTime + seekInterval)
        seek(to: newTime)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

