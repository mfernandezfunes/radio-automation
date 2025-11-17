//
//  GlobalAudioMixer.swift
//  musica-player
//
//  Created by Martin Fernandez on 16/11/2025.
//

import Foundation
import AVFoundation
import Combine

/// Global audio mixer that receives audio from all players and applies global effects
class GlobalAudioMixer: ObservableObject {
    static let shared = GlobalAudioMixer()
    
    // Global audio engine
    private let globalEngine = AVAudioEngine()
    
    // Global mixer node that receives all players
    private let globalMixerNode = AVAudioMixerNode()
    
    // Global output equalizer
    private var globalOutputEqualizer: AVAudioUnitEQ?
    
    // Global VU meter levels (for output monitoring)
    @Published var leftLevel: Float = 0.0
    @Published var rightLevel: Float = 0.0
    
    // Output equalizer properties
    @Published var outputEqualizerEnabled: Bool = false
    @Published var outputEqualizerLowGain: Float = 0.0 // dB
    @Published var outputEqualizerMidGain: Float = 0.0 // dB
    @Published var outputEqualizerHighGain: Float = 0.0 // dB
    
    // Global output volume (master volume)
    @Published var outputVolume: Float = 1.0 {
        didSet {
            // Control the mainMixerNode volume of the global engine
            globalEngine.mainMixerNode.volume = outputVolume
            // Update both players' mainMixerNode volumes
            updatePlayerVolumes()
        }
    }
    
    // Global stereo balance
    @Published var stereoBalance: Float = 0.0 { // -1.0 (left) to 1.0 (right), 0.0 = center
        didSet {
            // Update both players' stereo balance
            updateStereoBalance()
        }
    }
    
    // Player mixer nodes (one for each player)
    private var player1MixerNode: AVAudioMixerNode?
    private var player2MixerNode: AVAudioMixerNode?
    
    // Reference to players for direct volume control
    private weak var player1: MusicPlayer?
    private weak var player2: MusicPlayer?
    
    /// Set player references for direct volume control
    func setPlayers(player1: MusicPlayer, player2: MusicPlayer) {
        self.player1 = player1
        self.player2 = player2
        // Apply current master volume and stereo balance
        updatePlayerVolumes()
        updateStereoBalance()
    }
    
    /// Update both players' mainMixerNode volumes based on master volume
    private func updatePlayerVolumes() {
        player1?.setMasterVolume(outputVolume)
        player2?.setMasterVolume(outputVolume)
    }
    
    /// Update both players' stereo balance
    private func updateStereoBalance() {
        player1?.setStereoBalance(stereoBalance)
        player2?.setStereoBalance(stereoBalance)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupGlobalEngine()
        observeEqualizerChanges()
    }
    
    private func setupGlobalEngine() {
        // Attach global mixer
        globalEngine.attach(globalMixerNode)
        
        // Create and attach global output equalizer
        let outputEQ = AVAudioUnitEQ(numberOfBands: 3)
        globalEngine.attach(outputEQ)
        globalOutputEqualizer = outputEQ
        configureOutputEqualizer(outputEQ)
        
        // Connect: globalMixer -> outputEQ -> mainMixerNode
        globalEngine.connect(globalMixerNode, to: outputEQ, format: nil)
        globalEngine.connect(outputEQ, to: globalEngine.mainMixerNode, format: nil)
        
        // Set initial output volume
        globalEngine.mainMixerNode.volume = outputVolume
        
        // Install tap on mainMixerNode for global VU meter monitoring
        // This shows the final output level after all processing
        let format = globalEngine.mainMixerNode.outputFormat(forBus: 0)
        globalEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            self?.processGlobalAudioBuffer(buffer)
        }
        
        // Start global engine
        do {
            try globalEngine.start()
        } catch {
            print("Failed to start global audio engine: \(error)")
        }
    }
    
    /// Process audio buffer for global VU meter
    private func processGlobalAudioBuffer(_ buffer: AVAudioPCMBuffer) {
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
        let leftLevel = (leftRMS * 0.7 + leftPeak * 0.3)
        let rightLevel = (rightRMS * 0.7 + rightPeak * 0.3)
        
        // Apply smoothing and normalize to 0-1 range
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Apply exponential smoothing
            let smoothingFactor: Float = 0.7
            let newLeft = self.leftLevel * smoothingFactor + leftLevel * (1 - smoothingFactor)
            let newRight = self.rightLevel * smoothingFactor + rightLevel * (1 - smoothingFactor)
            
            // Normalize: Scale to make typical levels visible
            let scale: Float = 2.0 // Sensitivity for output VU meter
            let normalizedLeft = min(newLeft * scale, 1.0)
            let normalizedRight = min(newRight * scale, 1.0)
            
            self.leftLevel = max(normalizedLeft, 0)
            self.rightLevel = max(normalizedRight, 0)
        }
    }
    
    /// Connect a player's output to the global mixer
    /// This uses a tap-based approach since players have their own engines
    func connectPlayerOutput(player: MusicPlayer, playerNumber: Int) {
        // Get the player's final output node
        guard let finalNode = player.getFinalOutputNode() else { return }
        
        // Create a mixer node in the global engine for this player
        let playerMixer = AVAudioMixerNode()
        globalEngine.attach(playerMixer)
        
        if playerNumber == 1 {
            player1MixerNode = playerMixer
        } else {
            player2MixerNode = playerMixer
        }
        
        // Connect player mixer to global mixer
        let format = globalMixerNode.inputFormat(forBus: 0)
        globalEngine.connect(playerMixer, to: globalMixerNode, format: format)
        
        // Note: We can't directly connect nodes from different engines
        // The player will need to use a tap to feed audio to this mixer
        // This is a limitation of AVAudioEngine architecture
    }
    
    /// Get the global mixer node - players should connect their output to this
    func getGlobalMixerNode() -> AVAudioMixerNode {
        return globalMixerNode
    }
    
    /// Get the global audio engine - for connecting player nodes
    /// Note: Players should use this engine instead of creating their own
    func getGlobalEngine() -> AVAudioEngine {
        return globalEngine
    }
    
    /// Check if global engine is running
    var isRunning: Bool {
        return globalEngine.isRunning
    }
    
    private func configureOutputEqualizer(_ eq: AVAudioUnitEQ) {
        // Low frequency (bass)
        let lowBand = eq.bands[0]
        lowBand.frequency = 80
        lowBand.gain = outputEqualizerLowGain
        lowBand.bandwidth = 1.0
        lowBand.filterType = .lowShelf
        lowBand.bypass = !outputEqualizerEnabled
        
        // Mid frequency
        let midBand = eq.bands[1]
        midBand.frequency = 1000
        midBand.gain = outputEqualizerMidGain
        midBand.bandwidth = 1.0
        midBand.filterType = .parametric
        midBand.bypass = !outputEqualizerEnabled
        
        // High frequency (treble)
        let highBand = eq.bands[2]
        highBand.frequency = 8000
        highBand.gain = outputEqualizerHighGain
        highBand.bandwidth = 1.0
        highBand.filterType = .highShelf
        highBand.bypass = !outputEqualizerEnabled
    }
    
    private func observeEqualizerChanges() {
        $outputEqualizerEnabled
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if let eq = self.globalOutputEqualizer {
                    eq.bands[0].bypass = !enabled
                    eq.bands[1].bypass = !enabled
                    eq.bands[2].bypass = !enabled
                    if enabled {
                        eq.bands[0].gain = self.outputEqualizerLowGain
                        eq.bands[1].gain = self.outputEqualizerMidGain
                        eq.bands[2].gain = self.outputEqualizerHighGain
                    } else {
                        eq.bands[0].gain = 0.0
                        eq.bands[1].gain = 0.0
                        eq.bands[2].gain = 0.0
                    }
                }
            }
            .store(in: &cancellables)
        
        $outputEqualizerLowGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if let eq = self.globalOutputEqualizer, self.outputEqualizerEnabled {
                    eq.bands[0].bypass = false
                    eq.bands[0].gain = value
                }
            }
            .store(in: &cancellables)
        
        $outputEqualizerMidGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if let eq = self.globalOutputEqualizer, self.outputEqualizerEnabled {
                    eq.bands[1].bypass = false
                    eq.bands[1].gain = value
                }
            }
            .store(in: &cancellables)
        
        $outputEqualizerHighGain
            .sink { [weak self] value in
                guard let self = self else { return }
                if let eq = self.globalOutputEqualizer, self.outputEqualizerEnabled {
                    eq.bands[2].bypass = false
                    eq.bands[2].gain = value
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        globalEngine.stop()
    }
}

