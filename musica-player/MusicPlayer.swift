//
//  MusicPlayer.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation
import AVFoundation
import Combine
import Accelerate

class MusicPlayer: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var nextSongDuration: TimeInterval? = nil // Duration of preloaded next song
    @Published var volume: Float = 0.5 {
        didSet {
            playerNode.volume = volume
        }
    }
    
    @Published var vuMeterSensitivity: Float = 1.1 // Sensitivity scale factor for VU meters (1.0 - 5.0)
    
    @Published var autoPlayNext: Bool = false // Auto-continue to next song when current finishes
    
    // Silence detection
    @Published var silenceDetectionEnabled: Bool = false // Enable automatic silence detection
    @Published var silenceThreshold: Float = 0.01 // RMS threshold below which audio is considered silent (0.0-1.0)
    @Published var silenceDuration: TimeInterval = 3.0 // Duration of silence before auto-stop (seconds)
    @Published var autoStopOnSilence: Bool = true // Automatically stop playback on long silence
    @Published var autoPlayFallbackOnSilence: Bool = false // Auto-play fallback content on silence
    @Published var isSilent: Bool = false // Current silence state
    @Published var silenceDurationDetected: TimeInterval = 0.0 // Current detected silence duration
    
    // Audio effects
    @Published var compressorEnabled: Bool = false
    @Published var compressorThreshold: Float = -20.0 // dB
    @Published var compressorRatio: Float = 4.0 // 1:1 to 20:1
    @Published var compressorAttack: Float = 0.001 // seconds
    @Published var compressorRelease: Float = 0.05 // seconds
    
    @Published var reverbEnabled: Bool = false
    @Published var reverbWetDryMix: Float = 30.0 // 0-100%
    @Published var reverbPreset: AVAudioUnitReverbPreset = .mediumHall
    
    @Published var delayEnabled: Bool = false
    @Published var delayTime: TimeInterval = 0.25 // seconds
    @Published var delayFeedback: Float = 30.0 // 0-100%
    @Published var delayWetDryMix: Float = 20.0 // 0-100%
    
    @Published var equalizerEnabled: Bool = false
    @Published var equalizerLowGain: Float = 0.0 // dB
    @Published var equalizerMidGain: Float = 0.0 // dB
    @Published var equalizerHighGain: Float = 0.0 // dB
    
    // AirPlay - Note: On macOS, AirPlay is managed by system preferences
    // The audioEngine automatically uses the system-selected output device
    @Published var airPlayInfo: String = "Usar Preferencias del Sistema"
    @Published var leftLevel: Float = 0.0
    @Published var rightLevel: Float = 0.0
    @Published var detectedBPM: Double? = nil // Detected beats per minute
    @Published var beatDetected: Bool = false // Real-time beat detection
    @Published var detectedKey: String? = nil // Detected musical key in Camelot format (e.g., "8A", "5B")
    @Published var detectedKeyName: String? = nil // Detected key in standard format (e.g., "A minor", "C major")
    
    // BPM Detection Parameters
    @Published var bpmDetectionThreshold: Float = 0.3 // Threshold for peak detection (0.0-1.0)
    @Published var bpmMinInterval: TimeInterval = 0.2 // Minimum time between beats (300 BPM max)
    @Published var bpmMaxInterval: TimeInterval = 2.0 // Maximum time between beats (30 BPM min)
    @Published var bpmMinBPM: Double = 30.0 // Minimum valid BPM
    @Published var bpmMaxBPM: Double = 300.0 // Maximum valid BPM
    @Published var bpmSmoothingWindow: Int = 5 // Window size for energy smoothing
    
    // Real-time Beat Detection Parameters
    @Published var beatSmoothingFactor: Float = 0.85 // Smoothing factor for energy (0.0-1.0)
    @Published var beatMinRelativeIncrease: Float = 0.15 // Minimum relative energy increase (0.0-1.0)
    @Published var beatStdDevMultiplier: Float = 1.5 // Standard deviation multiplier for threshold
    @Published var beatMinThresholdMultiplier: Float = 1.15 // Minimum threshold multiplier above average
    @Published var beatMinEnergyThreshold: Float = 0.001 // Minimum energy threshold
    
    // Advanced beat detection parameters
    @Published var useSpectralFlux: Bool = true // Use spectral flux for better beat detection
    @Published var useHighFrequencyContent: Bool = true // Use HFC for percussion detection
    @Published var spectralFluxWeight: Float = 0.6 // Weight for spectral flux (0.0-1.0)
    @Published var hfcWeight: Float = 0.4 // Weight for high-frequency content (0.0-1.0)
    
    // Playback controls
    @Published var playbackRate: Float = 1.0 { // 0.5x to 2.0x speed
        didSet {
            updatePlaybackRate()
        }
    }
    @Published var stereoBalance: Float = 0.0 { // -1.0 (left) to 1.0 (right), 0.0 = center
        didSet {
            updateStereoBalance()
        }
    }
    @Published var crossfadeEnabled: Bool = false
    @Published var crossfadeDuration: TimeInterval = 5.0 // seconds
    @Published var fadeInEnabled: Bool = false
    @Published var fadeInDuration: TimeInterval = 2.0 // seconds
    @Published var fadeOutEnabled: Bool = false
    @Published var fadeOutDuration: TimeInterval = 2.0 // seconds
    
    private let seekInterval: TimeInterval = 10.0 // 10 seconds for rewind/fast forward
    
    // AVAudioEngine components
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var nextAudioFile: AVAudioFile? // Preloaded next song
    private var nextPreloadedSongId: UUID? // ID of the preloaded song
    private var nextScheduled: Bool = false // Track if next song is already scheduled
    private var currentAccessingURL: URL?
    private var nextAccessingURL: URL? // Access for next song
    
    // Audio effects units
    private var compressorUnit: AVAudioUnitEffect?
    private var reverbUnit: AVAudioUnitReverb?
    private var delayUnit: AVAudioUnitDelay?
    private var equalizerUnit: AVAudioUnitEQ?
    private var varispeedUnit: AVAudioUnitVarispeed? // For playback rate control
    private var mixerNode: AVAudioMixerNode? // For stereo balance
    
    // Audio routing
    private var effectChain: [AVAudioNode] = []
    private var tapInstalled: Bool = false
    
    // Time tracking
    private var playbackTimer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var isSeeking: Bool = false // Flag to prevent autoplay during seek
    
    // Silence detection tracking
    private var silenceStartTime: Date? = nil // When current silence period started
    private var lastAudioDetectedTime: Date? = nil // Last time audio was detected above threshold
    
    // Beat detection
    private var energyHistory: [Float] = []
    private var beatTimes: [TimeInterval] = []
    private var lastBeatTime: TimeInterval = 0
    private let maxHistorySize = 1000 // Keep last 1000 energy values
    
    // Real-time beat detection
    private var recentEnergyValues: [Float] = []
    private var lastBeatDetectionTime: TimeInterval = 0
    private var averageEnergy: Float = 0.0
    private var smoothedEnergy: Float = 0.0 // Smoothed energy for beat detection
    private let energyHistorySize = 43 // Keep last 43 values (~1 second at 44.1kHz with 1024 buffer)
    
    // Advanced beat detection - Spectral analysis
    private var previousSpectrum: [Float] = [] // Previous FFT spectrum for spectral flux
    private var recentSpectralFlux: [Float] = [] // Recent spectral flux values
    private var recentHFC: [Float] = [] // Recent High-Frequency Content values
    private var smoothedSpectralFlux: Float = 0.0
    private var smoothedHFC: Float = 0.0
    private let fftSize: Int = 1024 // FFT size for spectral analysis
    private var fftSetup: vDSP_DFT_Setup? = nil // FFT setup for Accelerate
    
    var playlist: Playlist
    let playerName: String // "Player 1" or "Player 2"
    weak var otherPlayer: MusicPlayer?
    
    init(playlist: Playlist, playerName: String = "Player") {
        self.playlist = playlist
        self.playerName = playerName
        super.init()
        
        setupAudioEngine()
        setupAudioEffects()
        detectOutputDevices()
        
        // Observe playlist changes
        playlist.$currentIndex
            .sink { [weak self] _ in
                self?.loadCurrentSong()
            }
            .store(in: &cancellables)
        
        // Observe nextIndex changes to preload the next song
        playlist.$nextIndex
            .sink { [weak self] nextIndex in
                guard let self = self else { return }
                
                // If nextIndex is nil, clear any preloaded files and scheduled items
                guard let nextIndex = nextIndex,
                      nextIndex >= 0,
                      nextIndex < self.playlist.items.count else {
                    // Clear preloaded files and scheduled items when nextIndex is cleared
                    if self.nextScheduled {
                        // Stop playerNode to clear scheduled items (only if not playing)
                        if !self.isPlaying {
                            self.playerNode.stop()
                        }
                        self.nextScheduled = false
                    }
                    if let nextURL = self.nextAccessingURL {
                        nextURL.stopAccessingSecurityScopedResource()
                        self.nextAccessingURL = nil
                    }
                    self.nextAudioFile = nil
                    self.nextPreloadedSongId = nil
                    self.nextSongDuration = nil
                    return
                }
                
                let nextItem = self.playlist.items[nextIndex]
                // Only preload if it's a song (not a command)
                if !nextItem.isCommand, let nextSong = nextItem.song {
                    // Preload the next song without playing it
                    // This loads the file into memory but doesn't start playback
                    self.preloadSong(nextSong)
                } else {
                    // If it's a command or not a song, clear any preloaded files and scheduled items
                    if self.nextScheduled {
                        // Stop playerNode to clear scheduled items (only if not playing)
                        if !self.isPlaying {
                            self.playerNode.stop()
                        }
                        self.nextScheduled = false
                    }
                    if let nextURL = self.nextAccessingURL {
                        nextURL.stopAccessingSecurityScopedResource()
                        self.nextAccessingURL = nil
                    }
                    self.nextAudioFile = nil
                    self.nextPreloadedSongId = nil
                    self.nextSongDuration = nil
                }
            }
            .store(in: &cancellables)
        
        // Observe effect changes
        observeEffectChanges()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        stopPlaybackTimer()
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        stopAudioEngine()
        
        // Release file access when destroying the player
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
        }
        if let url = nextAccessingURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func setupAudioEngine() {
        // Attach player node to engine
        audioEngine.attach(playerNode)
        
        // Build effect chain once - effects will always be connected
        buildEffectChainOnce()
        
        // Install tap on mixer for level monitoring
        let mixer = audioEngine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            self?.processAudioBuffer(buffer)
        }
        tapInstalled = true
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func buildEffectChainOnce() {
        // Create and attach all effect units (always connected)
        // They will be controlled via parameters, not by adding/removing from chain
        
        // Varispeed unit for playback rate control
        let varispeed = AVAudioUnitVarispeed()
        audioEngine.attach(varispeed)
        varispeedUnit = varispeed
        
        // Create a mixer node for stereo balance control
        let mixer = AVAudioMixerNode()
        audioEngine.attach(mixer)
        mixerNode = mixer
        
        // Delay unit
        let delay = AVAudioUnitDelay()
        audioEngine.attach(delay)
        delayUnit = delay
        
        // Reverb unit
        let reverb = AVAudioUnitReverb()
        audioEngine.attach(reverb)
        reverbUnit = reverb
        
        // Equalizer unit
        let eq = AVAudioUnitEQ(numberOfBands: 3)
        audioEngine.attach(eq)
        equalizerUnit = eq
        
        // Connect: player -> varispeed -> delay -> reverb -> eq -> mixer -> mainMixer
        // Always connected, effects controlled via wet/dry mix
        audioEngine.connect(playerNode, to: varispeed, format: nil)
        audioEngine.connect(varispeed, to: delay, format: nil)
        audioEngine.connect(delay, to: reverb, format: nil)
        audioEngine.connect(reverb, to: eq, format: nil)
        audioEngine.connect(eq, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Initialize effect parameters
        configureDelay(delay)
        configureReverb(reverb)
        configureEqualizer(eq)
        updatePlaybackRate()
        updateStereoBalance()
        
        // Set initial wet/dry mix based on enabled state
        updateEffectStates()
    }
    
    private func updateEffectStates() {
        // Update delay wet/dry mix (0% = bypass, 100% = full effect)
        if let delay = delayUnit {
            delay.wetDryMix = delayEnabled ? delayWetDryMix : 0.0
        }
        
        // Update reverb wet/dry mix
        if let reverb = reverbUnit {
            reverb.wetDryMix = reverbEnabled ? reverbWetDryMix : 0.0
        }
        
        // For equalizer, we can't bypass easily, so we set gains to 0 when disabled
        if let eq = equalizerUnit {
            if equalizerEnabled {
                eq.bands[0].gain = equalizerLowGain
                eq.bands[1].gain = equalizerMidGain
                eq.bands[2].gain = equalizerHighGain
            } else {
                eq.bands[0].gain = 0.0
                eq.bands[1].gain = 0.0
                eq.bands[2].gain = 0.0
            }
        }
    }
    
    private func setupAudioEffects() {
        // Create audio effect units
        // These will be attached and connected when enabled
    }
    
    private func rebuildEffectChain() {
        // Stop engine first
        let wasRunning = audioEngine.isRunning
        if wasRunning {
            audioEngine.stop()
        }
        
        // Remove existing tap safely
        let mixer = audioEngine.mainMixerNode
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }
        
        // Detach all effect units
        if let compressor = compressorUnit {
            audioEngine.detach(compressor)
        }
        if let reverb = reverbUnit {
            audioEngine.detach(reverb)
        }
        if let delay = delayUnit {
            audioEngine.detach(delay)
        }
        if let eq = equalizerUnit {
            audioEngine.detach(eq)
        }
        
        // Reset effect chain
        effectChain.removeAll()
        compressorUnit = nil
        reverbUnit = nil
        delayUnit = nil
        equalizerUnit = nil
        
        // Build effect chain based on enabled effects
        var currentNode: AVAudioNode = playerNode
        
        // Compressor - Using AVAudioUnitEQ for dynamic range compression effect
        // Note: Full compressor requires AVAudioUnitVarispeed or custom processing
        // For now, we'll skip compressor as AVAudioUnitEffect doesn't have built-in compressor
        // Compressor can be implemented using AVAudioUnitEQ with dynamic gain adjustment
        
        // Delay (before reverb for better sound)
        if delayEnabled {
            let delay = AVAudioUnitDelay()
            audioEngine.attach(delay)
            configureDelay(delay)
            effectChain.append(delay)
            currentNode = delay
            delayUnit = delay
        }
        
        // Reverb
        if reverbEnabled {
            let reverb = AVAudioUnitReverb()
            audioEngine.attach(reverb)
            configureReverb(reverb)
            effectChain.append(reverb)
            currentNode = reverb
            reverbUnit = reverb
        }
        
        // Equalizer
        if equalizerEnabled {
            let eq = AVAudioUnitEQ(numberOfBands: 3)
            audioEngine.attach(eq)
            configureEqualizer(eq)
            effectChain.append(eq)
            currentNode = eq
            equalizerUnit = eq
        }
        
        // Connect chain to mixer (reuse mixer variable declared above)
        if effectChain.isEmpty {
            audioEngine.connect(playerNode, to: mixer, format: nil)
        } else {
            // Connect player to first effect
            audioEngine.connect(playerNode, to: effectChain[0], format: nil)
            
            // Connect effects in chain
            for i in 0..<effectChain.count - 1 {
                audioEngine.connect(effectChain[i], to: effectChain[i + 1], format: nil)
            }
            
            // Connect last effect to mixer
            audioEngine.connect(effectChain.last!, to: mixer, format: nil)
        }
        
        // Install tap for level monitoring
        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            self?.processAudioBuffer(buffer)
        }
        tapInstalled = true
        
        // Restart engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to restart audio engine: \(error)")
        }
    }
    
    // Compressor will be implemented using dynamic gain adjustment in processAudioBuffer
    // For now, compressor is disabled as AVAudioUnitEffect doesn't provide compressor
    
    private func configureReverb(_ reverb: AVAudioUnitReverb) {
        reverb.loadFactoryPreset(reverbPreset)
        reverb.wetDryMix = reverbWetDryMix
    }
    
    func refreshReverbPreset() {
        reverbUnit?.loadFactoryPreset(reverbPreset)
    }
    
    private func configureDelay(_ delay: AVAudioUnitDelay) {
        delay.delayTime = delayTime
        delay.feedback = delayFeedback
        delay.wetDryMix = delayWetDryMix
        delay.lowPassCutoff = 15000
    }
    
    private func configureEqualizer(_ eq: AVAudioUnitEQ) {
        // Low frequency (bass)
        let lowBand = eq.bands[0]
        lowBand.frequency = 80
        lowBand.gain = equalizerLowGain
        lowBand.bandwidth = 1.0
        lowBand.filterType = .lowShelf
        
        // Mid frequency
        let midBand = eq.bands[1]
        midBand.frequency = 1000
        midBand.gain = equalizerMidGain
        midBand.bandwidth = 1.0
        midBand.filterType = .parametric
        
        // High frequency (treble)
        let highBand = eq.bands[2]
        highBand.frequency = 8000
        highBand.gain = equalizerHighGain
        highBand.bandwidth = 1.0
        highBand.filterType = .highShelf
    }
    
    private func detectOutputDevices() {
        // Note: AVAudioSession is iOS-specific
        // On macOS, we use AVAudioEngine's outputNode which respects system audio preferences
        // AirPlay devices appear automatically in system preferences
        // We'll provide a way to refresh/check available devices
        updateAvailableDevices()
    }
    
    private func updateAvailableDevices() {
        // On macOS, output devices are managed by the system
        // The audioEngine.outputNode automatically uses the system-selected output
        // We can't programmatically select AirPlay, but we can detect if it's available
    }
    
    private func observeEffectChanges() {
        // Note: Compressor disabled for now as it requires custom implementation
        // Observe compressor changes (disabled)
        // $compressorEnabled
        //     .sink { [weak self] _ in self?.rebuildEffectChain() }
        //     .store(in: &cancellables)
        
        $reverbEnabled
            .sink { [weak self] enabled in
                guard let self = self else { return }
                // Immediately update reverb wet/dry mix when toggled
                if let reverb = self.reverbUnit {
                    reverb.wetDryMix = enabled ? self.reverbWetDryMix : 0.0
                }
                self.updateEffectStates()
            }
            .store(in: &cancellables)
        
        $delayEnabled
            .sink { [weak self] enabled in
                guard let self = self else { return }
                // Immediately update delay wet/dry mix when toggled
                if let delay = self.delayUnit {
                    if enabled {
                        delay.wetDryMix = self.delayWetDryMix
                    } else {
                        // When disabling, set wet/dry to 0 and reset delay buffer
                        delay.wetDryMix = 0.0
                        // Reset delay time briefly to clear buffer, then restore
                        let currentTime = delay.delayTime
                        delay.delayTime = 0.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            delay.delayTime = currentTime
                        }
                    }
                }
                self.updateEffectStates()
            }
            .store(in: &cancellables)
        
        $equalizerEnabled
            .sink { [weak self] enabled in
                guard let self = self else { return }
                // Immediately update equalizer gains when toggled
                if let eq = self.equalizerUnit {
                    if enabled {
                        eq.bands[0].gain = self.equalizerLowGain
                        eq.bands[1].gain = self.equalizerMidGain
                        eq.bands[2].gain = self.equalizerHighGain
                    } else {
                        eq.bands[0].gain = 0.0
                        eq.bands[1].gain = 0.0
                        eq.bands[2].gain = 0.0
                    }
                }
                self.updateEffectStates()
            }
            .store(in: &cancellables)
        
        // Observe parameter changes - update in real-time without rebuilding chain
        $reverbWetDryMix
            .sink { [weak self] value in
                guard let self = self else { return }
                if self.reverbEnabled {
                    self.reverbUnit?.wetDryMix = value
                }
            }
            .store(in: &cancellables)
        
        $delayTime
            .sink { [weak self] value in
                self?.delayUnit?.delayTime = TimeInterval(value)
            }
            .store(in: &cancellables)
        
        $delayFeedback
            .sink { [weak self] value in
                self?.delayUnit?.feedback = value
            }
            .store(in: &cancellables)
        
        $delayWetDryMix
            .sink { [weak self] value in
                guard let self = self else { return }
                if self.delayEnabled {
                    self.delayUnit?.wetDryMix = value
                } else {
                    self.delayUnit?.wetDryMix = 0.0
                }
            }
            .store(in: &cancellables)
        
        $equalizerLowGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if self.equalizerEnabled {
                    self.equalizerUnit?.bands[0].gain = value
                }
            }
            .store(in: &cancellables)
        
        $equalizerMidGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if self.equalizerEnabled {
                    self.equalizerUnit?.bands[1].gain = value
                }
            }
            .store(in: &cancellables)
        
        $equalizerHighGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if self.equalizerEnabled {
                    self.equalizerUnit?.bands[2].gain = value
                }
            }
            .store(in: &cancellables)
    }
    
    private func stopAudioEngine() {
        if tapInstalled {
            audioEngine.mainMixerNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        playerNode.stop()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    // Preload a song without stopping current playback or playing it
    // This function loads the file into memory AND schedules it in the playerNode
    // but does NOT start playback. This allows for instant playback when the song becomes current.
    func preloadSong(_ song: Song) {
        // IMPORTANT: This function calls scheduleFile() but NOT play()
        // The file is loaded, scheduled, and ready for instant playback
        
        // Clear any previously scheduled next song
        // Note: We can't stop the playerNode if it's playing, so we'll handle this differently
        // We'll track that we have a scheduled file, and when loadCurrentSong() is called,
        // it will stop() which clears the queue, then we'll use the preloaded file
        
        // Release previous next file access if exists
        if let previousNextURL = nextAccessingURL {
            previousNextURL.stopAccessingSecurityScopedResource()
            nextAccessingURL = nil
        }
        nextAudioFile = nil
        nextPreloadedSongId = nil
        nextScheduled = false
        nextSongDuration = nil
        
        // Get accessible URL using security bookmark
        guard let accessibleURL = song.accessibleURL() else {
            return
        }
        
        // Access resource securely
        guard accessibleURL.startAccessingSecurityScopedResource() else {
            return
        }
        
        nextAccessingURL = accessibleURL
        nextPreloadedSongId = song.id
        
        // Load audio file in background to prepare it
        // This is done asynchronously to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                accessibleURL.stopAccessingSecurityScopedResource()
                return
            }
            
            do {
                // Create AVAudioFile object
                let file = try AVAudioFile(forReading: accessibleURL)
                
                // Calculate duration while we have the file
                let sampleRate = file.processingFormat.sampleRate
                let frameCount = Double(file.length)
                let calculatedDuration = frameCount / sampleRate
                
                DispatchQueue.main.async {
                    self.nextAudioFile = file
                    self.nextSongDuration = calculatedDuration.isFinite && calculatedDuration > 0 ? calculatedDuration : nil
                    
                    // Schedule the file in the playerNode for instant playback later
                    // AVAudioPlayerNode supports queuing multiple files, so we can schedule
                    // even when playing - it will play after the current file finishes
                    if !self.isPlaying {
                        // Player is stopped/paused, safe to schedule
                        self.playerNode.scheduleFile(file, at: nil) { [weak self] in
                            DispatchQueue.main.async {
                                self?.playerDidFinishPlaying()
                            }
                        }
                        self.nextScheduled = true
                    } else {
                        // Player is playing - we can still schedule it in the queue
                        // It will play after the current file finishes
                        // However, we need to be careful: if the current song changes
                        // before this scheduled file plays, we'll need to handle that in loadCurrentSong()
                        // For now, we'll schedule it but mark it as "next scheduled"
                        // so loadCurrentSong() knows to use it when it becomes current
                        self.playerNode.scheduleFile(file, at: nil) { [weak self] in
                            DispatchQueue.main.async {
                                // This callback will only fire if this file actually plays
                                // If loadCurrentSong() is called before it plays, stop() will clear it
                                self?.playerDidFinishPlaying()
                            }
                        }
                        self.nextScheduled = true
                    }
                }
            } catch {
                // If loading fails, clean up resources
                accessibleURL.stopAccessingSecurityScopedResource()
                self.nextAccessingURL = nil
                self.nextPreloadedSongId = nil
            }
        }
    }
    
    func loadCurrentSong() {
        guard let song = playlist.currentSong else {
            stop()
            return
        }
        
        // Stop current playback
        stop()
        
        // Reset beat detection
        resetBeatDetection()
        
        // Release previous access if it exists
        if let previousURL = currentAccessingURL {
            previousURL.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
        
        // Check if we already have this file preloaded (compare by song ID)
        if let preloadedFile = nextAudioFile,
           let preloadedSongId = nextPreloadedSongId,
           preloadedSongId == song.id {
            // Use the preloaded file
            audioFile = preloadedFile
            if let nextURL = nextAccessingURL {
                currentAccessingURL = nextURL
            }
            nextAudioFile = nil
            nextAccessingURL = nil
            nextPreloadedSongId = nil
            
            // Note: stop() was called above, which clears the playerNode queue
            // So even if the file was scheduled, we need to reschedule it in play()
            // Reset nextScheduled to false so play() will schedule it
            nextScheduled = false
            
            // Clear nextSongDuration since it's now the current song
            nextSongDuration = nil
            
            // Get duration
            let sampleRate = preloadedFile.processingFormat.sampleRate
            let frameCount = Double(preloadedFile.length)
            duration = frameCount / sampleRate
            
            // Reset time tracking
            currentTime = 0
            pausedTime = 0
            
            // Start analyzing for BPM in background
            analyzeBPM(for: preloadedFile)
            return
        }
        
        // Release next file access if it's not the current song
        if let nextURL = nextAccessingURL {
            nextURL.stopAccessingSecurityScopedResource()
            nextAccessingURL = nil
        }
        nextAudioFile = nil
        nextPreloadedSongId = nil
        nextSongDuration = nil
        
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
            
            // Start analyzing for BPM in background
            analyzeBPM(for: file)
            
        } catch {
            print("Failed to load audio file: \(error)")
            audioFile = nil
        }
    }
    
    private func resetBeatDetection() {
        energyHistory.removeAll()
        beatTimes.removeAll()
        lastBeatTime = 0
        detectedBPM = nil
        detectedKey = nil
        detectedKeyName = nil
        recentEnergyValues.removeAll()
        lastBeatDetectionTime = 0
        averageEnergy = 0.0
        smoothedEnergy = 0.0
        beatDetected = false
        
        // Reset advanced beat detection
        previousSpectrum.removeAll()
        recentSpectralFlux.removeAll()
        recentHFC.removeAll()
        smoothedSpectralFlux = 0.0
        smoothedHFC = 0.0
        
        // Reset silence detection
        silenceStartTime = nil
        lastAudioDetectedTime = nil
        isSilent = false
        silenceDurationDetected = 0.0
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
        
        // Schedule file for playback (only if not already scheduled from preload)
        // If the file was preloaded and scheduled, it's already in the playerNode queue
        if !nextScheduled {
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
        } else {
            // File was already scheduled during preload, just clear the flag
            nextScheduled = false
        }
        
        // Start playback
        playerNode.play()
        isPlaying = true
        
        // Start time tracking
        startTime = Date().addingTimeInterval(-pausedTime)
        startPlaybackTimer()
        
        // Apply fade in if enabled
        if pausedTime == 0 { // Only fade in when starting from beginning
            applyFadeIn()
        }
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
        
        // Clear scheduled next song flag
        nextScheduled = false
        
        stopPlaybackTimer()
        
        // Reset levels
        leftLevel = 0.0
        rightLevel = 0.0
        
        // Reset silence detection
        silenceStartTime = nil
        lastAudioDetectedTime = nil
        isSilent = false
        silenceDurationDetected = 0.0
        
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
        
        // Check if current item is a command
        if let currentItem = playlist.currentItem, currentItem.isCommand {
            // Execute command
            executeCommand(currentItem.command!)
            
            // After executing command, check what's next and preload if it's an audio
            if let itemAfterCommand = playlist.peekNextItem() {
                if !itemAfterCommand.isCommand, let nextSong = itemAfterCommand.song {
                    // Preload the next audio file
                    preloadSong(nextSong)
                }
                // If it's a command, it will be executed when we process next item
            }
            
            // Move to next item after command execution
            // The executeCommand may have already advanced the playlist, so check what's next
            if let nextItem = playlist.nextItem() {
                if nextItem.isCommand {
                    // If next is also a command, process it recursively
                    processNextItem(for: self)
                } else {
                    // Load and play next song
                    loadCurrentSong()
                    if autoPlayNext || crossfadeEnabled {
                        play()
                    }
                }
            } else {
                stop()
            }
            return
        }
        
        // Apply fade out before transitioning
        applyFadeOut { [weak self] in
            guard let self = self else { return }
            
            // Handle repeat mode
            if self.playlist.repeatMode == .one {
                // Repeat current song
                self.loadCurrentSong()
                self.play()
            } else if self.autoPlayNext || self.crossfadeEnabled {
                // Automatically play next item if auto-play or crossfade is enabled
                if let nextItem = self.playlist.nextItem() {
                    if nextItem.isCommand {
                        // Execute command - nextItem() already advanced the index to the command
                        let command = nextItem.command!
                        let commandStopsCurrentPlayer = self.willCommandStopCurrentPlayer(command)
                        
                        self.executeCommand(command)
                        
                        // After executing command, check what's next and preload if it's an audio
                        if let itemAfterCommand = self.playlist.peekNextItem() {
                            if !itemAfterCommand.isCommand, let nextSong = itemAfterCommand.song {
                                // Preload the next audio file
                                self.preloadSong(nextSong)
                            }
                            // If it's a command, it will be executed when we process next item
                        }
                        
                        // Only continue processing if the command didn't stop the current player
                        // Commands like stopPlayer1AndPlayNextInPlayer2 stop the current player,
                        // so we shouldn't continue processing in this player
                        if !commandStopsCurrentPlayer {
                            // After command execution, process the next item (which may be another command or song)
                            // The index is already at the command, so we need to advance to the next item
                            if let itemAfterCommand = self.playlist.nextItem() {
                                if itemAfterCommand.isCommand {
                                    // If next is also a command, process it recursively
                                    self.processNextItem(for: self)
                                } else {
                                    // Load and play next song
                                    self.loadCurrentSong()
                                    self.play()
                                }
                            } else {
                                self.stop()
                            }
                        }
                        // If command stopped current player, do nothing (command already handled the transition)
                    } else {
                        // Play next song
                        self.loadCurrentSong()
                        self.play()
                    }
                } else {
                    self.stop()
                }
            } else {
                self.stop()
            }
        }
    }
    
    // Helper function to check if a command will stop the current player
    private func willCommandStopCurrentPlayer(_ command: PlaylistCommand) -> Bool {
        let isPlayer1 = playerName == "Player 1"
        let isPlayer2 = playerName == "Player 2"
        
        switch command.commandType {
        case .stopPlayer1AndPlayNextInPlayer2:
            return isPlayer1 // Stops Player 1
        case .stopPlayer2AndPlayNextInPlayer1:
            return isPlayer2 // Stops Player 2
        case .stopPlayer1:
            return isPlayer1 // Stops Player 1
        case .stopPlayer2:
            return isPlayer2 // Stops Player 2
        case .pausePlayer1, .pausePlayer2, .resumePlayer1, .resumePlayer2:
            return false // These don't stop, they pause/resume
        }
    }
    
    // Helper function to process next item (command or song) for a player
    func processNextItem(for targetPlayer: MusicPlayer, forcePlay: Bool = false) {
        if let nextItem = targetPlayer.playlist.nextItem() {
            if nextItem.isCommand {
                // Execute command
                targetPlayer.executeCommand(nextItem.command!)
                
                // After executing command, check what's next and preload if it's an audio
                if let itemAfterCommand = targetPlayer.playlist.peekNextItem() {
                    if !itemAfterCommand.isCommand, let nextSong = itemAfterCommand.song {
                        // Preload the next audio file
                        targetPlayer.preloadSong(nextSong)
                    }
                    // If it's a command, it will be executed when we process next item
                }
                
                // Recursively process next item after command
                processNextItem(for: targetPlayer, forcePlay: forcePlay)
            } else {
                // Load and play next song
                targetPlayer.loadCurrentSong()
                // If forcePlay is true (from command), always play. Otherwise check autoPlayNext/crossfade
                if forcePlay || targetPlayer.autoPlayNext || targetPlayer.crossfadeEnabled {
                    targetPlayer.play()
                }
            }
        }
    }
    
    func executeCommand(_ command: PlaylistCommand) {
        guard let otherPlayer = otherPlayer else { return }
        
        let isPlayer1 = playerName == "Player 1"
        let isPlayer2 = playerName == "Player 2"
        
        switch command.commandType {
        case .stopPlayer1AndPlayNextInPlayer2:
            if isPlayer1 {
                // Stop self (Player 1) and play next in Player 2
                stop()
                processNextItem(for: otherPlayer, forcePlay: true)
            } else if isPlayer2 {
                // Stop Player 1 and play next in self (Player 2)
                otherPlayer.stop()
                processNextItem(for: self, forcePlay: true)
            }
            
        case .stopPlayer2AndPlayNextInPlayer1:
            if isPlayer1 {
                // Stop Player 2 and play next in self (Player 1)
                otherPlayer.stop()
                processNextItem(for: self, forcePlay: true)
            } else if isPlayer2 {
                // Stop self (Player 2) and play next in Player 1
                stop()
                processNextItem(for: otherPlayer, forcePlay: true)
            }
            
        case .stopPlayer1:
            if isPlayer1 {
                stop()
            } else if isPlayer2 {
                otherPlayer.stop()
            }
            
        case .stopPlayer2:
            if isPlayer1 {
                otherPlayer.stop()
            } else if isPlayer2 {
                stop()
            }
            
        case .pausePlayer1:
            if isPlayer1 {
                pause()
            } else if isPlayer2 {
                otherPlayer.pause()
            }
            
        case .pausePlayer2:
            if isPlayer1 {
                otherPlayer.pause()
            } else if isPlayer2 {
                pause()
            }
            
        case .resumePlayer1:
            if isPlayer1 {
                play()
            } else if isPlayer2 {
                otherPlayer.play()
            }
            
        case .resumePlayer2:
            if isPlayer1 {
                otherPlayer.play()
            } else if isPlayer2 {
                play()
            }
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
    
    // MARK: - Beat Detection
    
    func analyzeBPM(for file: AVAudioFile) {
        // Analyze audio file in background to detect BPM
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let format = file.processingFormat
            let frameCount = file.length
            let bufferSize: AVAudioFrameCount = 4096
            
            var energyValues: [Float] = []
            var sampleRate = format.sampleRate
            
            // Read file in chunks
            file.framePosition = 0
            while file.framePosition < frameCount {
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
                    break
                }
                
                do {
                    try file.read(into: buffer)
                    let energy = self.calculateEnergy(from: buffer)
                    energyValues.append(energy)
                } catch {
                    break
                }
            }
            
            // Detect beats from energy values
            let bpm = self.detectBPMFromEnergy(energyValues, sampleRate: sampleRate, bufferSize: Int(bufferSize))
            
            // Detect musical key
            let (camelotKey, keyName) = self.detectMusicalKey(for: file)
            
            DispatchQueue.main.async {
                self.detectedBPM = bpm
                self.detectedKey = camelotKey
                self.detectedKeyName = keyName
            }
        }
    }
    
    private func calculateEnergy(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0, channelCount > 0 else { return 0 }
        
        var sum: Float = 0.0
        let leftChannel = channelData[0]
        let rightChannel = channelCount > 1 ? channelData[1] : channelData[0]
        
        // Calculate energy from both channels
        for frame in 0..<frameLength {
            let leftSample = leftChannel[frame]
            let rightSample = rightChannel[frame]
            let mono = (leftSample + rightSample) / 2.0
            sum += mono * mono
        }
        
        return sqrt(sum / Float(frameLength))
    }
    
    private func detectBPMFromEnergy(_ energyValues: [Float], sampleRate: Double, bufferSize: Int) -> Double? {
        guard energyValues.count > 10 else { return nil }
        
        // Calculate local energy average
        let windowSize = bpmSmoothingWindow
        var smoothedEnergy: [Float] = []
        
        for i in 0..<energyValues.count {
            let start = max(0, i - windowSize)
            let end = min(energyValues.count, i + windowSize + 1)
            let window = energyValues[start..<end]
            let average = window.reduce(0, +) / Float(window.count)
            smoothedEnergy.append(average)
        }
        
        // Detect peaks (beats)
        var beatIntervals: [Double] = []
        var lastPeakIndex = 0
        let maxEnergy = smoothedEnergy.max() ?? 0
        let threshold = maxEnergy * bpmDetectionThreshold
        
        for i in 1..<(smoothedEnergy.count - 1) {
            if smoothedEnergy[i] > smoothedEnergy[i-1] &&
               smoothedEnergy[i] > smoothedEnergy[i+1] &&
               smoothedEnergy[i] > threshold {
                
                if lastPeakIndex > 0 {
                    let interval = Double(i - lastPeakIndex) * Double(bufferSize) / sampleRate
                    if interval >= bpmMinInterval && interval <= bpmMaxInterval {
                        beatIntervals.append(interval)
                    }
                }
                lastPeakIndex = i
            }
        }
        
        guard beatIntervals.count >= 3 else { return nil }
        
        // Calculate average BPM
        let averageInterval = beatIntervals.reduce(0, +) / Double(beatIntervals.count)
        let bpm = 60.0 / averageInterval
        
        // Validate BPM range
        guard bpm >= bpmMinBPM && bpm <= bpmMaxBPM else { return nil }
        
        return bpm
    }
    
    // MARK: - Musical Key Detection
    
    /// Detect musical key using chromagram analysis and convert to Camelot Wheel
    func detectMusicalKey(for file: AVAudioFile) -> (camelotKey: String?, keyName: String?) {
        let format = file.processingFormat
        let frameCount = file.length
        let bufferSize: AVAudioFrameCount = 4096
        
        // Chromagram: 12 semitones (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
        var chromagram = [Float](repeating: 0, count: 12)
        var totalFrames: Int = 0
        
        // Read file in chunks and analyze chromagram
        file.framePosition = 0
        while file.framePosition < frameCount {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
                break
            }
            
            do {
                try file.read(into: buffer)
                let chroma = calculateChromagram(from: buffer, sampleRate: format.sampleRate)
                for i in 0..<12 {
                    chromagram[i] += chroma[i]
                }
                totalFrames += Int(buffer.frameLength)
            } catch {
                break
            }
        }
        
        // Normalize chromagram
        if totalFrames > 0 {
            for i in 0..<12 {
                chromagram[i] /= Float(totalFrames)
            }
        }
        
        // Find key using Krumhansl-Schmuckler key-finding algorithm
        let (keyIndex, mode) = findKeyFromChromagram(chromagram)
        
        // Convert to standard key name
        let keyNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let keyName = keyNames[keyIndex] + (mode == 0 ? " major" : " minor")
        
        // Convert to Camelot Wheel
        let camelotKey = convertToCamelotWheel(keyIndex: keyIndex, mode: mode)
        
        return (camelotKey, keyName)
    }
    
    /// Calculate chromagram from audio buffer
    private func calculateChromagram(from buffer: AVAudioPCMBuffer, sampleRate: Double) -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            return [Float](repeating: 0, count: 12)
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0, channelCount > 0 else {
            return [Float](repeating: 0, count: 12)
        }
        
        // Create mono signal
        var monoSignal = [Float](repeating: 0, count: frameLength)
        let leftChannel = channelData[0]
        let rightChannel = channelCount > 1 ? channelData[1] : channelData[0]
        
        for i in 0..<frameLength {
            monoSignal[i] = (leftChannel[i] + rightChannel[i]) / 2.0
        }
        
        // Calculate chromagram using simplified pitch detection
        // For real-time performance, we'll use autocorrelation-based pitch detection
        var chromagram = [Float](repeating: 0, count: 12)
        
        // Use a simplified approach: analyze frequency content in semitone bands
        // This is a simplified version - full implementation would use FFT and pitch class profile
        let windowSize = min(frameLength, 2048)
        let windowedSignal = Array(monoSignal.prefix(windowSize))
        
        // Apply window function
        var windowed = [Float](repeating: 0, count: windowSize)
        let twoPi = Float.pi * 2.0
        for i in 0..<windowSize {
            let windowValue = 0.5 * (1.0 - cos(twoPi * Float(i) / Float(windowSize - 1)))
            windowed[i] = windowedSignal[i] * windowValue
        }
        
        // Calculate energy in frequency bands corresponding to semitones
        // Reference frequency: A4 = 440 Hz
        let referenceFreq: Float = 440.0
        let sampleRateFloat = Float(sampleRate)
        
        for semitone in 0..<12 {
            // Calculate frequency for this semitone (relative to C)
            // C is 3 semitones below A
            let semitoneOffset = Float(semitone - 3)
            let frequency = referenceFreq * pow(2.0, semitoneOffset / 12.0)
            
            // Find energy around this frequency using autocorrelation
            var energy: Float = 0.0
            let period = Int(sampleRateFloat / frequency)
            
            if period > 0 && period < windowSize / 2 {
                // Calculate autocorrelation at this period
                for i in 0..<(windowSize - period) {
                    energy += windowed[i] * windowed[i + period]
                }
                energy = abs(energy) / Float(windowSize - period)
            }
            
            chromagram[semitone] = energy
        }
        
        return chromagram
    }
    
    /// Find key from chromagram using Krumhansl-Schmuckler algorithm
    private func findKeyFromChromagram(_ chromagram: [Float]) -> (keyIndex: Int, mode: Int) {
        // Krumhansl-Schmuckler key profiles (major and minor)
        let majorProfile: [Float] = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        let minorProfile: [Float] = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
        
        var maxCorrelation: Float = -Float.infinity
        var bestKey = 0
        var bestMode = 0 // 0 = major, 1 = minor
        
        // Normalize chromagram
        let chromaSum = chromagram.reduce(0, +)
        guard chromaSum > 0 else {
            return (0, 0) // Default to C major
        }
        
        let normalizedChroma = chromagram.map { $0 / chromaSum }
        
        // Test all 12 keys in both major and minor
        for key in 0..<12 {
            // Test major mode
            var correlation: Float = 0.0
            for i in 0..<12 {
                let profileIndex = (i - key + 12) % 12
                correlation += normalizedChroma[i] * majorProfile[profileIndex]
            }
            
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestKey = key
                bestMode = 0
            }
            
            // Test minor mode
            correlation = 0.0
            for i in 0..<12 {
                let profileIndex = (i - key + 12) % 12
                correlation += normalizedChroma[i] * minorProfile[profileIndex]
            }
            
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestKey = key
                bestMode = 1
            }
        }
        
        return (bestKey, bestMode)
    }
    
    /// Convert key index and mode to Camelot Wheel format
    private func convertToCamelotWheel(keyIndex: Int, mode: Int) -> String {
        // Camelot Wheel mapping:
        // Inner ring (A) = minor keys
        // Outer ring (B) = major keys
        
        // Mapping: C=0, C#=1, D=2, D#=3, E=4, F=5, F#=6, G=7, G#=8, A=9, A#=10, B=11
        // Camelot: 1A-12A (minor), 1B-12B (major)
        
        let camelotMapping: [(major: Int, minor: Int)] = [
            (5, 8),   // C major = 5B, A minor = 8A
            (12, 3),  // C# major = 12B, A# minor = 3A
            (7, 10),  // D major = 7B, B minor = 10A
            (2, 5),   // D# major = 2B, C minor = 5A
            (9, 12),  // E major = 9B, C# minor = 12A
            (4, 7),   // F major = 4B, D minor = 7A
            (11, 2),  // F# major = 11B, D# minor = 2A
            (6, 9),   // G major = 6B, E minor = 9A
            (1, 4),   // G# major = 1B, F minor = 4A
            (8, 11),  // A major = 8B, F# minor = 11A
            (3, 6),   // A# major = 3B, G minor = 6A
            (10, 1)   // B major = 10B, G# minor = 1A
        ]
        
        let mapping = camelotMapping[keyIndex]
        let camelotNumber = mode == 0 ? mapping.major : mapping.minor
        let camelotLetter = mode == 0 ? "B" : "A"
        
        return "\(camelotNumber)\(camelotLetter)"
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
        
        // Calculate energy for beat detection (mono) - use raw RMS/peak combination
        // This is before normalization, so we get the actual energy level
        let rawMonoEnergy = (leftLevel + rightLevel) / 2.0
        
        // Apply smoothing to energy (similar to VU meters) to avoid false positives
        smoothedEnergy = smoothedEnergy * beatSmoothingFactor + rawMonoEnergy * (1 - beatSmoothingFactor)
        
        // Calculate advanced beat detection features if enabled
        var spectralFluxValue: Float = 0.0
        var hfcValue: Float = 0.0
        
        if useSpectralFlux || useHighFrequencyContent {
            // Create mono buffer for spectral analysis
            var monoBuffer = [Float](repeating: 0, count: frameLength)
            for i in 0..<frameLength {
                monoBuffer[i] = (leftChannel[i] + rightChannel[i]) / 2.0
            }
            
            // Calculate spectral features
            if useSpectralFlux {
                spectralFluxValue = calculateSpectralFlux(from: monoBuffer)
            }
            
            if useHighFrequencyContent {
                hfcValue = calculateHighFrequencyContent(from: monoBuffer)
            }
        }
        
        // Real-time beat detection using improved methods
        detectBeatImproved(energy: smoothedEnergy, spectralFlux: spectralFluxValue, hfc: hfcValue)
        
        // Silence detection
        if silenceDetectionEnabled {
            detectSilence(averageLevel: (leftLevel + rightLevel) / 2.0)
        }
        
        // Apply smoothing and normalize to 0-1 range
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isPlaying else { return }
            
            // Apply exponential smoothing
            let smoothingFactor: Float = 0.7
            let newLeft = self.leftLevel * smoothingFactor + leftLevel * (1 - smoothingFactor)
            let newRight = self.rightLevel * smoothingFactor + rightLevel * (1 - smoothingFactor)
            
            // Normalize: RMS values are typically in range 0.0 to ~0.3 for normal audio
            // Use adjustable sensitivity scaling to avoid saturation
            // Scale to make typical levels (0.05-0.2) visible without saturating
            let scale = self.vuMeterSensitivity // Use adjustable sensitivity
            let normalizedLeft = min(newLeft * scale, 1.0)
            let normalizedRight = min(newRight * scale, 1.0)
            
            self.leftLevel = max(normalizedLeft, 0)
            self.rightLevel = max(normalizedRight, 0)
        }
    }
    
    // MARK: - Silence Detection
    
    /// Detect silence in audio and handle auto-stop or fallback playback
    private func detectSilence(averageLevel: Float) {
        let currentTime = Date()
        let threshold = silenceThreshold
        
        // Check if current level is below threshold (silent)
        if averageLevel < threshold {
            // Audio is below threshold - check if we're already tracking silence
            if silenceStartTime == nil {
                // Start tracking silence
                silenceStartTime = currentTime
            }
            
            // Calculate how long we've been silent
            if let startTime = silenceStartTime {
                let silenceDuration = currentTime.timeIntervalSince(startTime)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isPlaying else { return }
                    self.isSilent = true
                    self.silenceDurationDetected = silenceDuration
                    
                    // Check if silence duration exceeds threshold
                    if silenceDuration >= self.silenceDuration {
                        // Long silence detected - take action
                        if self.autoStopOnSilence {
                            // Auto-stop playback
                            self.stop()
                            print("Auto-stopped due to silence of \(silenceDuration) seconds")
                        } else if self.autoPlayFallbackOnSilence {
                            // Auto-play fallback content (if implemented)
                            // For now, just move to next song
                            self.next()
                        }
                    }
                }
            }
        } else {
            // Audio detected above threshold - clear silence tracking
            if silenceStartTime != nil {
                silenceStartTime = nil
                lastAudioDetectedTime = currentTime
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isSilent = false
                    self.silenceDurationDetected = 0.0
                }
            } else {
                lastAudioDetectedTime = currentTime
            }
        }
    }
    
    // MARK: - Advanced Beat Detection Methods
    
    /// Calculate Spectral Flux - detects changes in frequency spectrum (better for beat detection)
    private func calculateSpectralFlux(from audioBuffer: [Float]) -> Float {
        guard audioBuffer.count >= 64 else { return 0.0 } // Need minimum samples
        
        // Use a simplified FFT approach with vDSP for real-time performance
        // For better performance, we'll use a smaller window and calculate magnitude spectrum
        let windowSize = min(audioBuffer.count, 512) // Use smaller window for real-time
        let windowedBuffer = Array(audioBuffer.prefix(windowSize))
        
        // Apply window function (Hanning window) to reduce spectral leakage
        var windowed = [Float](repeating: 0, count: windowSize)
        let twoPi = Float.pi * 2.0
        for i in 0..<windowSize {
            let windowValue = 0.5 * (1.0 - cos(twoPi * Float(i) / Float(windowSize - 1)))
            windowed[i] = windowedBuffer[i] * windowValue
        }
        
        // For real-time performance, use a simplified spectral analysis
        // Calculate energy in different frequency bands using bandpass filtering
        // This is faster than full FFT and sufficient for beat detection
        
        // Divide into frequency bands (simplified approach)
        let numBands = 32 // Use 32 frequency bands
        var spectrum = [Float](repeating: 0, count: numBands)
        
        // Calculate energy in each band using simple filtering
        let samplesPerBand = windowSize / numBands
        for band in 0..<numBands {
            var bandEnergy: Float = 0.0
            let startIdx = band * samplesPerBand
            let endIdx = min(startIdx + samplesPerBand, windowSize)
            
            for i in startIdx..<endIdx {
                bandEnergy += windowed[i] * windowed[i]
            }
            spectrum[band] = sqrt(bandEnergy / Float(endIdx - startIdx))
        }
        
        // Calculate spectral flux: sum of positive differences between current and previous spectrum
        var flux: Float = 0.0
        if previousSpectrum.count == spectrum.count {
            for i in 0..<spectrum.count {
                let diff = spectrum[i] - previousSpectrum[i]
                if diff > 0 {
                    flux += diff
                }
            }
        } else {
            // First frame - just calculate total energy
            flux = spectrum.reduce(0, +)
        }
        
        // Update previous spectrum
        previousSpectrum = spectrum
        
        // Normalize by spectrum size
        return flux / Float(spectrum.count)
    }
    
    /// Calculate High-Frequency Content - emphasizes transients (good for percussion)
    private func calculateHighFrequencyContent(from audioBuffer: [Float]) -> Float {
        guard audioBuffer.count >= 64 else { return 0.0 }
        
        // HFC weights higher frequencies more heavily
        // HFC = sum of (magnitude[i] * i^2) for all frequency bins
        // For real-time, we'll use a simplified approach: emphasize high-frequency energy
        
        let windowSize = min(audioBuffer.count, 512)
        let windowedBuffer = Array(audioBuffer.prefix(windowSize))
        
        // Apply window
        var windowed = [Float](repeating: 0, count: windowSize)
        let twoPi = Float.pi * 2.0
        for i in 0..<windowSize {
            let windowValue = 0.5 * (1.0 - cos(twoPi * Float(i) / Float(windowSize - 1)))
            windowed[i] = windowedBuffer[i] * windowValue
        }
        
        // For HFC, calculate energy in frequency bands with emphasis on high frequencies
        // Divide into frequency bands and weight higher frequencies more
        let numBands = 32
        var hfc: Float = 0.0
        
        let samplesPerBand = windowSize / numBands
        for band in 0..<numBands {
            var bandEnergy: Float = 0.0
            let startIdx = band * samplesPerBand
            let endIdx = min(startIdx + samplesPerBand, windowSize)
            
            for i in startIdx..<endIdx {
                bandEnergy += windowed[i] * windowed[i]
            }
            
            let magnitude = sqrt(bandEnergy / Float(endIdx - startIdx))
            
            // Weight by band index squared (higher frequencies weighted more)
            // Higher band index = higher frequency
            let frequencyWeight = Float(band * band)
            hfc += magnitude * frequencyWeight
        }
        
        // Normalize
        let maxWeight = Float((numBands - 1) * (numBands - 1))
        return hfc / maxWeight
    }
    
    /// Improved beat detection combining energy, spectral flux, and HFC
    private func detectBeatImproved(energy: Float, spectralFlux: Float, hfc: Float) {
        // Only detect beats when playing
        guard isPlaying else { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Initialize lastBeatDetectionTime if it's the first time
        if lastBeatDetectionTime == 0 {
            lastBeatDetectionTime = currentTime
        }
        
        // Combine different detection methods
        var combinedSignal: Float = 0.0
        var totalWeight: Float = 0.0
        
        // Energy-based detection (always used as baseline)
        recentEnergyValues.append(energy)
        if recentEnergyValues.count > energyHistorySize {
            recentEnergyValues.removeFirst()
        }
        
        // Normalize energy for combination
        if recentEnergyValues.count >= 15 {
            averageEnergy = recentEnergyValues.reduce(0, +) / Float(recentEnergyValues.count)
            if averageEnergy > 0 {
                let normalizedEnergy = (energy - averageEnergy) / averageEnergy
                combinedSignal += normalizedEnergy * 0.3
                totalWeight += 0.3
            }
        }
        
        // Spectral Flux (if enabled)
        if useSpectralFlux && spectralFlux > 0 {
            recentSpectralFlux.append(spectralFlux)
            if recentSpectralFlux.count > energyHistorySize {
                recentSpectralFlux.removeFirst()
            }
            
            if recentSpectralFlux.count >= 10 {
                let avgFlux = recentSpectralFlux.reduce(0, +) / Float(recentSpectralFlux.count)
                if avgFlux > 0 {
                    let normalizedFlux = (spectralFlux - avgFlux) / avgFlux
                    smoothedSpectralFlux = smoothedSpectralFlux * 0.9 + normalizedFlux * 0.1
                    combinedSignal += smoothedSpectralFlux * spectralFluxWeight
                    totalWeight += spectralFluxWeight
                }
            }
        }
        
        // High-Frequency Content (if enabled)
        if useHighFrequencyContent && hfc > 0 {
            recentHFC.append(hfc)
            if recentHFC.count > energyHistorySize {
                recentHFC.removeFirst()
            }
            
            if recentHFC.count >= 10 {
                let avgHFC = recentHFC.reduce(0, +) / Float(recentHFC.count)
                if avgHFC > 0 {
                    let normalizedHFC = (hfc - avgHFC) / avgHFC
                    smoothedHFC = smoothedHFC * 0.9 + normalizedHFC * 0.1
                    combinedSignal += smoothedHFC * hfcWeight
                    totalWeight += hfcWeight
                }
            }
        }
        
        // Normalize combined signal
        if totalWeight > 0 {
            combinedSignal /= totalWeight
        }
        
        // Need enough history to detect beats
        guard recentEnergyValues.count >= 15 else { return }
        guard averageEnergy > beatMinEnergyThreshold else { return }
        
        // Calculate dynamic threshold for combined signal
        var signalHistory: [Float] = []
        if useSpectralFlux && recentSpectralFlux.count >= 10 {
            signalHistory.append(contentsOf: recentSpectralFlux.suffix(15))
        }
        if useHighFrequencyContent && recentHFC.count >= 10 {
            signalHistory.append(contentsOf: recentHFC.suffix(15))
        }
        signalHistory.append(contentsOf: recentEnergyValues.suffix(15))
        
        let avgSignal = signalHistory.reduce(0, +) / Float(signalHistory.count)
        let variance = signalHistory.map { pow($0 - avgSignal, 2) }.reduce(0, +) / Float(signalHistory.count)
        let stdDev = sqrt(variance)
        
        let dynamicThreshold = avgSignal + stdDev * beatStdDevMultiplier
        let minThreshold = avgSignal * beatMinThresholdMultiplier
        let threshold = max(dynamicThreshold, minThreshold)
        
        // Detect beat if combined signal exceeds threshold and enough time has passed
        let timeSinceLastBeat = currentTime - lastBeatDetectionTime
        
        // Use detected BPM if available, otherwise use adaptive interval
        let minInterval: TimeInterval
        if let bpm = detectedBPM, bpm > 0 {
            minInterval = (60.0 / bpm) * 0.5
        } else {
            minInterval = bpmMinInterval
        }
        
        // Check if signal spike is significant enough
        let signalIncrease = combinedSignal - avgSignal
        let relativeIncrease = avgSignal > 0 ? signalIncrease / avgSignal : 0
        
        // Detect beat: combined signal exceeds threshold, enough time passed, and significant increase
        if combinedSignal > threshold && timeSinceLastBeat >= minInterval && relativeIncrease > beatMinRelativeIncrease {
            lastBeatDetectionTime = currentTime
            
            // Trigger beat indicator
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isPlaying else { return }
                self.beatDetected = true
                
                // Turn off after a short duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                    self?.beatDetected = false
                }
            }
        }
    }
    
    private func detectBeat(energy: Float) {
        // Only detect beats when playing
        guard isPlaying else { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Initialize lastBeatDetectionTime if it's the first time
        if lastBeatDetectionTime == 0 {
            lastBeatDetectionTime = currentTime
        }
        
        // Add smoothed energy to history
        recentEnergyValues.append(energy)
        if recentEnergyValues.count > energyHistorySize {
            recentEnergyValues.removeFirst()
        }
        
        // Need enough history to detect beats
        guard recentEnergyValues.count >= 15 else { return }
        
        // Calculate average energy (using a longer window for stability)
        averageEnergy = recentEnergyValues.reduce(0, +) / Float(recentEnergyValues.count)
        
        // Only detect beats if we have meaningful audio
        // For raw energy values (typically 0.0-0.3), use a very low threshold
        // The default beatMinEnergyThreshold (0.001) should work for most cases
        guard averageEnergy > beatMinEnergyThreshold else { return }
        
        // Calculate variance to determine dynamic threshold
        let variance = recentEnergyValues.map { pow($0 - averageEnergy, 2) }.reduce(0, +) / Float(recentEnergyValues.count)
        let stdDev = sqrt(variance)
        
        // Use a more conservative threshold to avoid saturation
        // Higher multiplier means less sensitive (similar to VU meters normalization)
        let dynamicThreshold = averageEnergy + stdDev * beatStdDevMultiplier
        
        // Minimum threshold based on average energy (percentage-based, like VU meters)
        let minThreshold = averageEnergy * beatMinThresholdMultiplier
        let threshold = max(dynamicThreshold, minThreshold)
        
        // Detect beat if energy exceeds threshold and enough time has passed
        let timeSinceLastBeat = currentTime - lastBeatDetectionTime
        
        // Use detected BPM if available, otherwise use adaptive interval
        let minInterval: TimeInterval
        if let bpm = detectedBPM, bpm > 0 {
            // Allow beats at up to 2x the detected BPM (for syncopation)
            minInterval = (60.0 / bpm) * 0.5
        } else {
            // If no BPM detected yet, use configured minimum interval
            minInterval = bpmMinInterval
        }
        
        // Check if energy spike is significant enough (more conservative)
        let energyIncrease = energy - averageEnergy
        let relativeIncrease = averageEnergy > 0 ? energyIncrease / averageEnergy : 0
        
        // Detect beat: energy exceeds threshold, enough time passed, and significant increase
        if energy > threshold && timeSinceLastBeat >= minInterval && relativeIncrease > beatMinRelativeIncrease {
            lastBeatDetectionTime = currentTime
            
            // Trigger beat indicator
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isPlaying else { return }
                self.beatDetected = true
                
                // Turn off after a short duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                    self?.beatDetected = false
                }
            }
        }
    }
    
    // MARK: - Playback Controls
    
    private func updatePlaybackRate() {
        varispeedUnit?.rate = playbackRate
    }
    
    private func updateStereoBalance() {
        // Stereo balance: -1.0 (left) to 1.0 (right), 0.0 = center
        // AVAudioMixerNode pan property ranges from -1.0 (left) to 1.0 (right)
        mixerNode?.pan = stereoBalance
    }
    
    // MARK: - Fade and Crossfade
    
    private var fadeInTimer: Timer?
    private var fadeOutTimer: Timer?
    
    private func applyFadeIn() {
        guard fadeInEnabled, fadeInDuration > 0 else { return }
        
        // Cancel any existing fade timers
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        
        // Store target volume before starting fade
        let targetVolume = volume
        
        // Start volume at 0 and fade in over fadeInDuration
        volume = 0.0
        
        let steps = 30 // Number of fade steps
        let stepDuration = fadeInDuration / Double(steps)
        let volumeStep = targetVolume / Float(steps)
        
        var currentStep = 0
        fadeInTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let newVolume = min(volumeStep * Float(currentStep), targetVolume)
            self.volume = newVolume
            
            if currentStep >= steps {
                self.volume = targetVolume
                timer.invalidate()
                self.fadeInTimer = nil
            }
        }
        RunLoop.current.add(fadeInTimer!, forMode: .common)
    }
    
    private func applyFadeOut(completion: @escaping () -> Void) {
        guard fadeOutEnabled, fadeOutDuration > 0 else {
            completion()
            return
        }
        
        // Cancel any existing fade timers
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        
        let startVolume = volume
        let steps = 30 // Number of fade steps
        let stepDuration = fadeOutDuration / Double(steps)
        let volumeStep = startVolume / Float(steps)
        
        var currentStep = 0
        fadeOutTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion()
                return
            }
            
            currentStep += 1
            let newVolume = max(startVolume - volumeStep * Float(currentStep), 0.0)
            self.volume = newVolume
            
            if currentStep >= steps {
                self.volume = 0.0
                timer.invalidate()
                self.fadeOutTimer = nil
                completion()
            }
        }
        RunLoop.current.add(fadeOutTimer!, forMode: .common)
    }
}
