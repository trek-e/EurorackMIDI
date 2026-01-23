import Foundation
import Combine
import MIDIKitCore
import os.log

private let logger = Logger(subsystem: "com.eurorack.midi", category: "ClockEngine")

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
final class ClockEngine: ObservableObject {
    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = ClockEngine()

    // MARK: - Published Properties (for UI observation)

    /// Tempo in beats per minute (clamped to 20-300)
    @Published var bpm: Double = 120.0 {
        didSet {
            let clampedBpm = max(20.0, min(300.0, bpm))
            if bpm != clampedBpm {
                bpm = clampedBpm
            } else {
                scheduleTimerUpdate()
            }
        }
    }

    /// Pulses per quarter note (4, 24, 48, or 96)
    @Published var ppqn: Int = 24 {
        didSet {
            scheduleTimerUpdate()
        }
    }

    /// Current transport state
    @Published private(set) var transportState: TransportState = .stopped

    /// Clock behavior mode
    @Published var clockMode: ClockMode = .auto

    /// Whether clock is currently sending pulses
    @Published private(set) var isClockRunning: Bool = false

    // MARK: - Non-published Properties

    /// Available PPQN options for UI picker
    /// 4 PPQN for Moog Matriarch and similar synths
    static let ppqnOptions = [4, 24, 48, 96]

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
    @discardableResult
    func processTap(autoApply: Bool = true) -> Double? {
        guard let calculatedBPM = tapTempo.tap() else { return nil }

        if autoApply {
            DispatchQueue.main.async {
                self.bpm = calculatedBPM
            }
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

    /// Lock for timer state only
    private let timerLock = NSLock()

    /// Current tick count since start
    private var tickCount: Int = 0

    /// Current beat position for song position pointer
    private var currentBeat: Int = 0

    /// Cached values for timer (updated atomically)
    private var cachedBpm: Double = 120.0
    private var cachedPpqn: Int = 24

    /// Pending timer update flag
    private var timerUpdatePending = false

    // MARK: - Initialization

    private init() {
        cachedBpm = bpm
        cachedPpqn = ppqn
    }

    // MARK: - Transport Control

    /// Start clock from the beginning
    func start() {
        guard transportState == .stopped else { return }

        timerLock.lock()
        tickCount = 0
        currentBeat = 0
        cachedBpm = bpm
        cachedPpqn = ppqn
        timerLock.unlock()

        transportState = .playing

        // Send MIDI Start message
        sendStart()

        // Start clock based on mode
        if clockMode == .auto {
            isClockRunning = true
            startTimer()
        }
    }

    /// Stop clock
    func stop() {
        guard transportState != .stopped else { return }

        // Stop clock based on mode
        if clockMode == .auto {
            stopTimer()
            isClockRunning = false
        }

        transportState = .stopped

        // Send MIDI Stop message
        sendStop()
    }

    /// Continue from current position
    func continue_() {
        guard transportState == .stopped else { return }

        timerLock.lock()
        cachedBpm = bpm
        cachedPpqn = ppqn
        timerLock.unlock()

        transportState = .playing

        // Send MIDI Continue message
        sendContinue()

        // Resume clock based on mode
        if clockMode == .auto && !isClockRunning {
            isClockRunning = true
            startTimer()
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
    func startClock() {
        guard !isClockRunning else { return }

        timerLock.lock()
        cachedBpm = bpm
        cachedPpqn = ppqn
        timerLock.unlock()

        isClockRunning = true
        startTimer()
    }

    /// Stop clock only (without affecting transport state)
    func stopClock() {
        guard isClockRunning else { return }

        stopTimer()
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
    func setPosition(midiBeat: Int) {
        timerLock.lock()
        currentBeat = midiBeat
        let clocksPerMidiBeat = cachedPpqn / 4
        tickCount = midiBeat * clocksPerMidiBeat
        timerLock.unlock()

        sendSongPositionPointer()
    }

    /// Reset position to start
    func rewind() {
        timerLock.lock()
        tickCount = 0
        currentBeat = 0
        timerLock.unlock()
    }

    // MARK: - Private Timer Methods

    private func startTimer() {
        timerLock.lock()
        let intervalSeconds = 60.0 / (cachedBpm * Double(cachedPpqn))
        timerLock.unlock()

        let newTimer = DispatchSource.makeTimerSource(queue: clockQueue)
        newTimer.schedule(
            deadline: .now(),
            repeating: intervalSeconds,
            leeway: .nanoseconds(0)
        )

        newTimer.setEventHandler { [weak self] in
            self?.tick()
        }

        timerLock.lock()
        timer = newTimer
        timerLock.unlock()

        newTimer.resume()
    }

    private func stopTimer() {
        timerLock.lock()
        let currentTimer = timer
        timer = nil
        timerLock.unlock()

        currentTimer?.cancel()
    }

    /// Schedule a timer update (debounced to avoid rapid restarts)
    private func scheduleTimerUpdate() {
        timerLock.lock()
        cachedBpm = bpm
        cachedPpqn = ppqn

        guard timer != nil else {
            timerLock.unlock()
            return
        }
        timerLock.unlock()

        // Stop and restart with new interval
        stopTimer()
        startTimer()
    }

    /// Called on clockQueue
    private func tick() {
        // Send timing clock event
        sendTimingClock()

        // Update internal counters
        timerLock.lock()
        tickCount += 1
        let currentTickCount = tickCount
        let clocksPerMidiBeat = max(1, cachedPpqn / 4)
        if currentTickCount % clocksPerMidiBeat == 0 {
            currentBeat += 1
        }
        timerLock.unlock()

        // Notify sequencer engine
        onTick?()
    }

    // MARK: - MIDI Event Sending

    private func sendTimingClock() {
        do {
            let event = MIDIEvent.timingClock()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            logger.debug("Failed to send timing clock: \(error.localizedDescription)")
        }
    }

    private func sendStart() {
        do {
            let event = MIDIEvent.start()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            logger.debug("Failed to send start: \(error.localizedDescription)")
        }
    }

    private func sendStop() {
        do {
            let event = MIDIEvent.stop()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            logger.debug("Failed to send stop: \(error.localizedDescription)")
        }
    }

    private func sendContinue() {
        do {
            let event = MIDIEvent.continue()
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            logger.debug("Failed to send continue: \(error.localizedDescription)")
        }
    }

    func sendSongPositionPointer() {
        timerLock.lock()
        let beat = currentBeat
        timerLock.unlock()

        do {
            let event = MIDIEvent.songPositionPointer(midiBeat: UInt14(beat))
            try MIDIConnectionManager.shared.sendSystemRealTime(event: event)
        } catch {
            logger.debug("Failed to send song position pointer: \(error.localizedDescription)")
        }
    }
}
