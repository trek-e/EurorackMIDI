import Foundation
import MIDIKitCore
import Observation

/// Clock behavior mode for transport/clock relationship
enum ClockMode: String, CaseIterable {
    /// Clock starts/stops automatically with transport
    case auto

    /// Clock controlled via separate button (independent of transport)
    case manual

    /// Clock always running regardless of transport state
    case always

    /// Display name for UI
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .manual: return "Manual"
        case .always: return "Always"
        }
    }

    /// Description for UI
    var description: String {
        switch self {
        case .auto: return "Clock follows transport"
        case .manual: return "Clock controlled separately"
        case .always: return "Clock runs continuously"
        }
    }
}

/// MIDI clock engine for generating tempo-synced clock signals
///
/// Sends MIDI clock events at configurable BPM and PPQN resolution.
/// Uses DispatchSourceTimer on a dedicated high-priority queue for precision timing.
@Observable
final class ClockEngine: @unchecked Sendable {
    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = ClockEngine()

    // MARK: - Lock for thread safety

    private let lock = NSLock()

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
    /// 4 PPQN for Moog Matriarch and similar synths
    static let ppqnOptions = [4, 24, 48, 96]

    /// Clock behavior mode
    var clockMode: ClockMode = .auto

    /// Whether clock is currently sending pulses (separate from transport for manual mode)
    private(set) var isClockRunning: Bool = false

    /// Callback invoked on each clock tick (for sequencer synchronization)
    var onTick: (() -> Void)?

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

    /// Current tick count since start (accessed from clock queue)
    private var _tickCount: Int = 0

    /// Current beat position for song position pointer (accessed from clock queue)
    private var _currentBeat: Int = 0

    /// Cached PPQN for clock queue access
    private var _cachedPpqn: Int = 24

    // MARK: - Initialization

    init() {
        _cachedPpqn = ppqn
    }

    // MARK: - Transport Control

    /// Start clock from the beginning
    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard transportState == .stopped else { return }

        _tickCount = 0
        _currentBeat = 0
        _cachedPpqn = ppqn
        transportState = .playing

        // Send MIDI Start message
        sendStart()

        // Start clock based on mode
        if clockMode == .auto {
            isClockRunning = true
            startTimerLocked()
        }
        // In manual/always mode, clock is controlled separately
    }

    /// Stop clock
    func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard transportState != .stopped else { return }

        // Stop clock based on mode
        if clockMode == .auto {
            stopTimerLocked()
            isClockRunning = false
        }
        // In manual/always mode, clock continues running

        transportState = .stopped

        // Send MIDI Stop message
        sendStop()
    }

    /// Continue from current position (named continue_ to avoid Swift keyword)
    func continue_() {
        lock.lock()
        defer { lock.unlock() }

        guard transportState == .stopped else { return }

        transportState = .playing

        // Send MIDI Continue message
        sendContinue()

        // Resume clock based on mode
        if clockMode == .auto && !isClockRunning {
            isClockRunning = true
            startTimerLocked()
        }
    }

    /// Toggle between playing and stopped
    func togglePlayback() {
        if transportState == .stopped {
            start()
        } else {
            stop()
        }
    }

    // MARK: - Clock Control (for manual/always modes)

    /// Start clock only (without affecting transport state)
    /// Used in manual or always clock modes
    func startClock() {
        lock.lock()
        defer { lock.unlock() }

        guard !isClockRunning else { return }

        isClockRunning = true
        startTimerLocked()
    }

    /// Stop clock only (without affecting transport state)
    /// Used in manual clock mode
    func stopClock() {
        lock.lock()
        defer { lock.unlock() }

        guard isClockRunning else { return }

        stopTimerLocked()
        isClockRunning = false
    }

    /// Toggle clock on/off (for manual mode button)
    func toggleClock() {
        if isClockRunning {
            stopClock()
        } else {
            startClock()
        }
    }

    /// Set transport position by MIDI beat number
    /// - Parameter midiBeat: Position in MIDI beats (1 beat = 6 MIDI clocks)
    func setPosition(midiBeat: Int) {
        lock.lock()
        _currentBeat = midiBeat
        // Calculate tick count from beat position
        let clocksPerMidiBeat = _cachedPpqn / 4
        _tickCount = midiBeat * clocksPerMidiBeat
        lock.unlock()

        // Send song position pointer to external gear
        sendSongPositionPointer()
    }

    /// Reset position to start
    func rewind() {
        lock.lock()
        defer { lock.unlock() }

        _tickCount = 0
        _currentBeat = 0
    }

    // MARK: - Private Methods (must be called with lock held)

    private func startTimerLocked() {
        let newTimer = DispatchSource.makeTimerSource(queue: clockQueue)

        let intervalSeconds = 60.0 / (bpm * Double(ppqn))
        newTimer.schedule(
            deadline: .now(),
            repeating: intervalSeconds,
            leeway: .nanoseconds(0)
        )

        newTimer.setEventHandler { [weak self] in
            self?.tick()
        }

        timer = newTimer
        newTimer.resume()
    }

    private func stopTimerLocked() {
        timer?.cancel()
        timer = nil
    }

    private func updateTimerInterval() {
        lock.lock()
        _cachedPpqn = ppqn

        // Only update if timer is running
        guard timer != nil else {
            lock.unlock()
            return
        }

        // Stop and restart timer with new interval
        stopTimerLocked()
        startTimerLocked()
        lock.unlock()
    }

    /// Called on clockQueue - must be thread-safe
    private func tick() {
        // Send timing clock event (thread-safe MIDI send)
        sendTimingClock()

        // Update internal counters
        lock.lock()
        _tickCount += 1
        let tickCount = _tickCount
        let clocksPerMidiBeat = _cachedPpqn / 4
        if tickCount % clocksPerMidiBeat == 0 {
            _currentBeat += 1
        }
        lock.unlock()

        // Notify sequencer engine of each tick
        onTick?()
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
        lock.lock()
        let beat = _currentBeat
        lock.unlock()

        do {
            let event = MIDIEvent.songPositionPointer(midiBeat: UInt14(beat))
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            print("ClockEngine: Failed to send song position pointer: \(error)")
        }
    }
}
