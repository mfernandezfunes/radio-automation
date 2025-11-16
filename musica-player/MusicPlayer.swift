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
            playerNode.volume = volume
        }
    }
    
    @Published var autoPlayNext: Bool = false // Auto-continue to next song when current finishes
    @Published var leftLevel: Float = 0.0
    @Published var rightLevel: Float = 0.0
    
    private let seekInterval: TimeInterval = 10.0 // 10 seconds for rewind/fast forward
    
    // AVAudioEngine components
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var currentAccessingURL: URL?
    
    // Time tracking
    private var playbackTimer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var isSeeking: Bool = false // Flag to prevent autoplay during seek
    
    var playlist: Playlist
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init()
        
        setupAudioEngine()
        
        // Observe playlist changes
        playlist.$currentIndex
            .sink { [weak self] _ in
                self?.loadCurrentSong()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        stopPlaybackTimer()
        stopAudioEngine()
        
        // Release file access when destroying the player
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func setupAudioEngine() {
        // Attach player node to engine
        audioEngine.attach(playerNode)
        
        // Connect player node to main mixer
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: mixer, format: nil)
        
        // Install tap on mixer for level monitoring
        // Use a larger buffer size for better performance
        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func stopAudioEngine() {
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        playerNode.stop()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    func loadCurrentSong() {
        guard let song = playlist.currentSong else {
            stop()
            return
        }
        
        // Stop current playback
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
        
        // Load audio file
        do {
            let file = try AVAudioFile(forReading: accessibleURL)
            audioFile = file
            
            // Get duration
            let sampleRate = file.processingFormat.sampleRate
            let frameCount = Double(file.length)
            duration = frameCount / sampleRate
            
            // Reset time tracking
            currentTime = 0
            pausedTime = 0
            
        } catch {
            print("Failed to load audio file: \(error)")
            audioFile = nil
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
        
        guard let file = audioFile else {
            loadCurrentSong()
            return
        }
        
        // If already playing, do nothing
        if isPlaying {
            return
        }
        
        // Ensure audio engine is running
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        // Schedule file for playback
        let format = file.processingFormat
        if pausedTime > 0 {
            // Resume from paused position
            let startFrame = AVAudioFramePosition(pausedTime * format.sampleRate)
            let frameCount = file.length - startFrame
            if frameCount > 0 {
                playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: AVAudioFrameCount(frameCount), at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        self?.playerDidFinishPlaying()
                    }
                }
            }
        } else {
            // Play from beginning
            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.playerDidFinishPlaying()
                }
            }
        }
        
        // Start playback
        playerNode.play()
        isPlaying = true
        
        // Start time tracking
        startTime = Date().addingTimeInterval(-pausedTime)
        startPlaybackTimer()
    }
    
    func pause() {
        guard isPlaying else { return }
        
        playerNode.pause()
        isPlaying = false
        
        // Update paused time
        if let start = startTime {
            pausedTime += Date().timeIntervalSince(start)
        }
        
        stopPlaybackTimer()
        
        // Reset levels when paused
        leftLevel = 0.0
        rightLevel = 0.0
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
        pausedTime = 0
        startTime = nil
        
        stopPlaybackTimer()
        
        // Reset levels
        leftLevel = 0.0
        rightLevel = 0.0
        
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
        guard let file = audioFile else { return }
        
        // Prevent multiple seeks from interfering with each other
        guard !isSeeking else { return }
        
        let wasPlaying = isPlaying
        let clampedTime = max(0, min(time, duration))
        
        // Set seeking flag to prevent autoplay callbacks and multiple seeks
        isSeeking = true
        
        // Update time immediately for responsive UI
        pausedTime = clampedTime
        currentTime = clampedTime
        
        // If was playing, do seamless seek
        if wasPlaying {
            let format = file.processingFormat
            let startFrame = AVAudioFramePosition(clampedTime * format.sampleRate)
            let frameCount = file.length - startFrame
            
            // Only schedule if there's enough audio left (at least 0.1 seconds)
            let minFrames = AVAudioFramePosition(0.1 * format.sampleRate)
            if frameCount > minFrames {
                // Stop first to clear any pending segments
                playerNode.stop()
                
                // Schedule new segment
                playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: AVAudioFrameCount(frameCount), at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        // Only trigger finish callback if not seeking
                        if let self = self, !self.isSeeking {
                            self.playerDidFinishPlaying()
                        }
                    }
                }
                
                // Restart playback immediately
                playerNode.play()
                // isPlaying remains true - don't change it
                
                // Reset start time to match the new position
                startTime = Date().addingTimeInterval(-clampedTime)
                
                // Restart timer immediately
                stopPlaybackTimer()
                startPlaybackTimer()
                
                // Clear seeking flag after playback has started
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.isSeeking = false
                }
            } else {
                // Too close to end, stop playback
                playerNode.stop()
                stopPlaybackTimer()
                isPlaying = false
                currentTime = duration
                pausedTime = duration
                isSeeking = false
            }
        } else {
            // Not playing, just update time
            isSeeking = false
        }
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
        // Don't process if we're in the middle of seeking
        guard !isSeeking else { return }
        
        stopPlaybackTimer()
        isPlaying = false
        currentTime = duration
        pausedTime = 0
        
        // Handle repeat mode
        if playlist.repeatMode == .one {
            // Repeat current song
            loadCurrentSong()
            play()
        } else if autoPlayNext {
            // Automatically play next song if auto-play is enabled
            if let nextSong = playlist.nextSong() {
                loadCurrentSong()
                play()
            } else {
                stop()
            }
        } else {
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
    
    // MARK: - Time Tracking
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateCurrentTime() {
        guard isPlaying, let start = startTime else { return }
        // startTime already has the offset applied (Date().addingTimeInterval(-pausedTime))
        // so elapsed is the actual playback time
        let elapsed = Date().timeIntervalSince(start)
        let newTime = min(max(elapsed, 0), duration)
        currentTime = newTime
        pausedTime = newTime
    }
    
    // MARK: - Audio Level Monitoring
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Only process if actually playing
        guard isPlaying else {
            // Gradually decrease levels when not playing
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.leftLevel = max(0, self.leftLevel * 0.9)
                self.rightLevel = max(0, self.rightLevel * 0.9)
            }
            return
        }
        
        guard let channelData = buffer.floatChannelData else {
            return
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0, channelCount > 0 else { return }
        
        // Handle mono audio (duplicate to both channels)
        let leftChannel = channelData[0]
        let rightChannel = channelCount > 1 ? channelData[1] : channelData[0]
        
        // Calculate peak and RMS for each channel
        var leftSum: Float = 0.0
        var rightSum: Float = 0.0
        var leftPeak: Float = 0.0
        var rightPeak: Float = 0.0
        
        for frame in 0..<frameLength {
            let leftSample = abs(leftChannel[frame])
            let rightSample = abs(rightChannel[frame])
            
            leftSum += leftSample * leftSample
            rightSum += rightSample * rightSample
            
            leftPeak = max(leftPeak, leftSample)
            rightPeak = max(rightPeak, rightSample)
        }
        
        // Calculate RMS
        let leftRMS = sqrt(leftSum / Float(frameLength))
        let rightRMS = sqrt(rightSum / Float(frameLength))
        
        // Use a combination of RMS and peak for better visualization
        // RMS gives average level, peak gives transient response
        let leftLevel = (leftRMS * 0.7 + leftPeak * 0.3)
        let rightLevel = (rightRMS * 0.7 + rightPeak * 0.3)
        
        // Apply smoothing and normalize to 0-1 range
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isPlaying else { return }
            
            // Apply exponential smoothing
            let smoothingFactor: Float = 0.7
            let newLeft = self.leftLevel * smoothingFactor + leftLevel * (1 - smoothingFactor)
            let newRight = self.rightLevel * smoothingFactor + rightLevel * (1 - smoothingFactor)
            
            // Normalize: RMS values are typically in range 0.0 to ~0.3 for normal audio
            // Use a more conservative scaling to avoid saturation
            // Scale to make typical levels (0.05-0.2) visible without saturating
            let scale: Float = 2.5 // Scale factor for visibility
            let normalizedLeft = min(newLeft * scale, 1.0)
            let normalizedRight = min(newRight * scale, 1.0)
            
            self.leftLevel = max(normalizedLeft, 0)
            self.rightLevel = max(normalizedRight, 0)
        }
    }
}
