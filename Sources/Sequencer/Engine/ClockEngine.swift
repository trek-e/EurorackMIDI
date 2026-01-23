import Foundation
import MIDIKitCore
import Observation

/// MIDI clock engine for generating tempo-synced clock signals
///
/// Sends MIDI clock events at configurable BPM and PPQN resolution.
/// Uses DispatchSourceTimer on a dedicated high-priority queue for precision timing.
@Observable
@MainActor
final class ClockEngine {
    // MARK: - Public Properties

    /// Tempo in beats per minute (clamped to 20-300)
    var bpm: Double = 120.0 {
        didSet {
            bpm = max(20.0, min(300.0, bpm))
            updateTimerInterval()
        }
    }

    /// Pulses per quarter note (24, 48, or 96)
    var ppqn: Int = 24 {
        didSet {
            updateTimerInterval()
        }
    }

    /// Current transport state
    private(set) var transportState: TransportState = .stopped

    /// Available PPQN options for UI picker
    let ppqnOptions = [24, 48, 96]

    /// Clock interval in milliseconds (for debugging)
    var clockIntervalMs: Double {
        (60.0 / (bpm * Double(ppqn))) * 1000.0
    }

    // MARK: - Tap Tempo

    /// Tap tempo calculator for live BPM input
    private let tapTempo = TapTempo()

    /// Process a tap and optionally update BPM
    /// - Parameter autoApply: If true, automatically applies calculated BPM
    /// - Returns: Calculated BPM if available (regardless of autoApply)
    @discardableResult
    func processTap(autoApply: Bool = true) -> Double? {
        guard let calculatedBPM = tapTempo.tap() else { return nil }

        if autoApply {
            bpm = calculatedBPM
        }

        return calculatedBPM
    }

    /// Reset tap tempo history
    func resetTapTempo() {
        tapTempo.reset()
    }

    /// Number of recorded taps (for UI feedback)
    var tapCount: Int {
        tapTempo.tapCount
    }

    // MARK: - Private Properties

    /// Timer for clock generation
    private var timer: DispatchSourceTimer?

    /// Dedicated high-priority queue for clock timing
    private let clockQueue = DispatchQueue(
        label: "com.eurorack.midi.clock",
        qos: .userInteractive
    )

    /// Current tick count since start
    private var tickCount: Int = 0

    /// Current beat position for song position pointer
    /// One MIDI beat = 6 MIDI clocks at 24 PPQN
    private var currentBeat: Int = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Transport Control

    /// Start clock from the beginning
    func start() {
        guard transportState == .stopped else { return }

        tickCount = 0
        currentBeat = 0
        transportState = .playing

        // Send MIDI Start message
        sendStart()

        // Create and start timer
        startTimer()
    }

    /// Stop clock
    func stop() {
        guard transportState != .stopped else { return }

        // Cancel timer first
        timer?.cancel()
        timer = nil

        transportState = .stopped

        // Send MIDI Stop message
        sendStop()
    }

    /// Continue from current position (named continue_ to avoid Swift keyword)
    func continue_() {
        guard transportState == .stopped else { return }

        transportState = .playing

        // Send MIDI Continue message
        sendContinue()

        // Resume timer
        startTimer()
    }

    /// Toggle between playing and stopped
    func togglePlayback() {
        if transportState == .stopped {
            start()
        } else {
            stop()
        }
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: clockQueue)

        let intervalSeconds = 60.0 / (bpm * Double(ppqn))
        timer?.schedule(
            deadline: .now(),
            repeating: intervalSeconds,
            leeway: .nanoseconds(0)
        )

        timer?.setEventHandler { [weak self] in
            self?.tick()
        }

        timer?.resume()
    }

    private func updateTimerInterval() {
        guard timer != nil else { return }

        let intervalSeconds = 60.0 / (bpm * Double(ppqn))
        timer?.schedule(
            deadline: .now(),
            repeating: intervalSeconds,
            leeway: .nanoseconds(0)
        )
    }

    private func tick() {
        // Send timing clock event
        sendTimingClock()

        tickCount += 1

        // Update beat position
        // One MIDI beat = 6 MIDI clocks (at any PPQN)
        // For 24 PPQN: 24 clocks/quarter = 4 MIDI beats/quarter
        let clocksPerMidiBeat = ppqn / 4
        if tickCount % clocksPerMidiBeat == 0 {
            currentBeat += 1
        }
    }

    // MARK: - MIDI Event Sending

    private func sendTimingClock() {
        do {
            let event = MIDIEvent.timingClock()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            // Log error but don't crash - device may have disconnected
            print("ClockEngine: Failed to send timing clock: \(error)")
        }
    }

    private func sendStart() {
        do {
            let event = MIDIEvent.start()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            print("ClockEngine: Failed to send start: \(error)")
        }
    }

    private func sendStop() {
        do {
            let event = MIDIEvent.stop()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            print("ClockEngine: Failed to send stop: \(error)")
        }
    }

    private func sendContinue() {
        do {
            let event = MIDIEvent.continue()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            print("ClockEngine: Failed to send continue: \(error)")
        }
    }

    /// Send song position pointer for current beat
    func sendSongPositionPointer() {
        do {
            let event = MIDIEvent.songPositionPointer(midiBeat: UInt14(currentBeat))
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            print("ClockEngine: Failed to send song position pointer: \(error)")
        }
    }
}
