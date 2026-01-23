import Foundation
import MIDIKitCore
import Observation

/// Engine for playing back patterns synchronized to clock
@Observable
@MainActor
final class SequencerEngine {
    static let shared = SequencerEngine()

    // MARK: - Properties

    /// Currently playing pattern
    var activePattern: Pattern?

    /// Current step position (0-based)
    private(set) var currentStep: Int = 0

    /// Notes currently playing (for note-off tracking)
    private var activeNotes: [(note: UInt7, channel: UInt4, offStep: Int)] = []

    /// Reference to clock engine
    private let clockEngine: ClockEngine

    /// Ticks per step (varies by PPQN and step resolution)
    private var ticksPerStep: Int {
        // Assuming 16th note steps: 1 step = 1 quarter note / 4
        // At 24 PPQN: 24 / 4 = 6 ticks per step
        clockEngine.ppqn / 4
    }

    /// Current tick within step
    private var tickInStep: Int = 0

    // MARK: - Initialization

    private init() {
        clockEngine = ClockEngine.shared
        setupTickCallback()
    }

    // MARK: - Tick Callback

    private func setupTickCallback() {
        // ClockEngine will call this on each tick
        clockEngine.onTick = { [weak self] in
            DispatchQueue.main.async {
                self?.processTick()
            }
        }
    }

    private func processTick() {
        guard let pattern = activePattern else { return }
        guard clockEngine.transportState == .playing else { return }

        tickInStep += 1

        // Check for step boundary
        if tickInStep >= ticksPerStep {
            tickInStep = 0
            advanceStep(pattern: pattern)
        }

        // Process note-offs
        processNoteOffs()
    }

    // MARK: - Step Advancement

    private func advanceStep(pattern: Pattern) {
        // Schedule notes for current step before advancing
        scheduleNotesForCurrentStep(pattern: pattern)

        // Move to next step
        currentStep = (currentStep + 1) % pattern.stepCount

        // If we wrapped to step 0, we completed a cycle
        if currentStep == 0 {
            tickInStep = 0
        }
    }

    // MARK: - Note Scheduling

    private func scheduleNotesForCurrentStep(pattern: Pattern) {
        let anySoloed = pattern.anySoloed

        for track in pattern.tracks {
            // Check if track should play
            guard track.shouldPlay(anySoloed: anySoloed) else { continue }

            // Get notes at current step
            let notes = track.notes(at: currentStep)

            for note in notes {
                sendNoteOn(note: note, track: track, pattern: pattern)
            }
        }
    }

    private func sendNoteOn(note: StepNote, track: Track, pattern: Pattern) {
        let midiNote = UInt7(note.note)
        // Convert 1-indexed track channel to 0-indexed MIDI channel
        let midiChannel = UInt4(track.channel - 1)

        // Apply track volume to velocity
        let adjustedVelocity = UInt7(Double(note.velocity) * track.volume)

        // Send note on
        do {
            try MIDIConnectionManager.shared.sendNoteOn(note: midiNote, velocity: adjustedVelocity)
        } catch {
            print("SequencerEngine: Failed to send note on: \(error)")
        }

        // Calculate when to send note-off (in steps)
        let offStep = (currentStep + Int(note.duration)) % (activePattern?.stepCount ?? 16)

        // Track for note-off
        activeNotes.append((note: midiNote, channel: midiChannel, offStep: offStep))
    }

    private func processNoteOffs() {
        // Find notes that need to be turned off
        let notesToOff = activeNotes.filter { $0.offStep == currentStep }

        for noteInfo in notesToOff {
            do {
                try MIDIConnectionManager.shared.sendNoteOff(note: noteInfo.note)
            } catch {
                print("SequencerEngine: Failed to send note off: \(error)")
            }
        }

        // Remove processed notes
        activeNotes.removeAll { $0.offStep == currentStep }
    }

    // MARK: - Transport Control

    func play(pattern: Pattern) {
        activePattern = pattern
        currentStep = 0
        tickInStep = 0
        activeNotes.removeAll()
        clockEngine.start()
    }

    func stop() {
        // Send all notes off
        allNotesOff()

        clockEngine.stop()
        currentStep = 0
        tickInStep = 0
        activeNotes.removeAll()
    }

    func pause() {
        // Send all notes off but maintain position
        allNotesOff()
        clockEngine.stop()
    }

    private func allNotesOff() {
        for noteInfo in activeNotes {
            try? MIDIConnectionManager.shared.sendNoteOff(note: noteInfo.note)
        }
        activeNotes.removeAll()
    }

    // MARK: - Pattern Switching

    /// Switch to a new pattern (respects launch quantize)
    func switchPattern(_ newPattern: Pattern, quantize: LaunchQuantize = .bar) {
        switch quantize {
        case .none:
            activePattern = newPattern
            // Don't reset step - continue playing

        case .beat:
            // Wait for next beat boundary
            // For now, just switch immediately (TODO: implement proper beat quantize)
            activePattern = newPattern

        case .bar:
            // Wait for next bar boundary
            // For now, just switch immediately (TODO: implement proper bar quantize)
            activePattern = newPattern
        }
    }
}
