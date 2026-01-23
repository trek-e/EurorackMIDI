# Phase 4: Sequencing - Research

**Researched:** 2026-01-23
**Domain:** MIDI Clock/Timing, Step Sequencer, Pattern Storage, iOS Audio Timing
**Confidence:** MEDIUM

## Summary

Phase 4 implements pattern composition and performance with tempo sync for Eurorack. The research covered four critical domains: (1) MIDI clock generation using MIDIKit's system real-time events, (2) high-precision timing strategies for iOS, (3) step sequencer grid UI patterns with SwiftUI Canvas, and (4) pattern storage using Codable with MIDIKitSMF for import/export.

The primary challenge is achieving jitter-free MIDI clock output. iOS introduces inherent timing variability from audio buffer callbacks, and the main thread is unsuitable for precise timing. Two approaches emerged: DispatchSourceTimer for deadline-based scheduling with low overhead, or dedicated audio thread timing using mach_wait_until() for sub-millisecond precision. MIDIKit provides all required MIDI events (timingClock, start, stop, continue, songPositionPointer) but does not include a built-in MIDI clock generator - this must be implemented in the app.

**Primary recommendation:** Use DispatchSourceTimer on a high-priority background queue for MIDI clock generation at 24/48/96 PPQN, with MIDIKit's .timingClock() events sent through the existing MIDIConnectionManager output connection.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MIDIKit | 0.10.7 | MIDI events and I/O | Already in project, provides .timingClock(), .start(), .stop(), .continue(), .songPositionPointer() |
| MIDIKitSMF | 0.10.7 | MIDI file read/write | Built into MIDIKit, handles SMF format 0/1 with tempo, note events |
| SwiftUI Canvas | iOS 15+ | High-performance grid rendering | Metal-backed immediate mode rendering for complex grids |
| DispatchSourceTimer | Native | High-precision timing | Deadline-based scheduling, lower overhead than Timer |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Combine | Native | Reactive state updates | Transport state changes, tempo updates |
| SwiftData | iOS 17+ | Pattern persistence | Pattern/arrangement storage (alternative to raw Codable) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| DispatchSourceTimer | The Spectacular Sync Engine | Obj-C library with C callback, more battle-tested but adds dependency |
| DispatchSourceTimer | CADisplayLink | Only useful if syncing to display refresh; adds display coupling |
| DispatchSourceTimer | mach_wait_until() | Lower overhead but requires real-time thread setup, more complex |
| SwiftData | UserDefaults + Codable | Simpler for small datasets, already used in ProfileManager |

**Installation:**
MIDIKit already in project. No additional dependencies required.

## Architecture Patterns

### Recommended Project Structure
```
Sources/
  Sequencer/
    Models/
      Pattern.swift           # Pattern, Track, StepNote data models
      Arrangement.swift       # Song/arrangement chain model
      TransportState.swift    # Play/stop/record state enum
    Engine/
      ClockEngine.swift       # MIDI clock generation (DispatchSourceTimer)
      SequencerEngine.swift   # Pattern playback, note scheduling
      SyncReceiver.swift      # External clock input (future)
    Managers/
      PatternManager.swift    # Pattern storage, banks, persistence
    Views/
      SequencerView.swift     # Main grid container
      PianoRollGridView.swift # Canvas-based note grid
      TransportView.swift     # Play/stop/tempo controls
      PatternBrowserView.swift # Bank/pattern selection
      MixerView.swift         # Track mute/solo/volume
```

### Pattern 1: Clock Engine with DispatchSourceTimer
**What:** Dedicated background timer for MIDI clock generation
**When to use:** All MIDI clock output scenarios
**Example:**
```swift
// Source: Apple DispatchSourceTimer documentation + MIDIKit events
final class ClockEngine: @unchecked Sendable {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.app.clock", qos: .userInteractive)

    var bpm: Double = 120.0 {
        didSet { updateTimerInterval() }
    }
    var ppqn: Int = 24  // 24, 48, or 96

    private var tickCount: Int = 0

    func start() {
        tickCount = 0

        // Send MIDI Start
        try? midiConnection.send(event: .start())

        // Create timer
        timer = DispatchSource.makeTimerSource(queue: queue)
        updateTimerInterval()

        timer?.setEventHandler { [weak self] in
            self?.tick()
        }
        timer?.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        try? midiConnection.send(event: .stop())
    }

    private func updateTimerInterval() {
        // Interval = 60 / (BPM * PPQN) seconds
        let intervalSeconds = 60.0 / (bpm * Double(ppqn))
        timer?.schedule(deadline: .now(), repeating: intervalSeconds, leeway: .nanoseconds(0))
    }

    private func tick() {
        // Send timing clock
        try? midiConnection.send(event: .timingClock())
        tickCount += 1
    }
}
```

### Pattern 2: Pattern Data Model with Codable
**What:** Hierarchical pattern structure for serialization
**When to use:** Pattern storage and MIDI file export
**Example:**
```swift
// Source: Project CONTEXT.md pattern specification
struct Pattern: Codable, Identifiable {
    let id: UUID
    var name: String
    var colorHex: String  // Store as hex for Codable compatibility
    var stepCount: Int  // 1-64
    var tracks: [Track]
    var swing: Double  // 0.0-1.0
    var triggerMode: TriggerMode
    var launchQuantize: LaunchQuantize
    var version: Int = 1  // For future migrations
}

struct Track: Codable, Identifiable {
    let id: UUID
    var channel: UInt8  // 1-16 (1-indexed for UI)
    var notes: [StepNote]
    var isMuted: Bool
    var isSoloed: Bool
    var volume: Double  // 0.0-1.0
}

struct StepNote: Codable, Identifiable {
    let id: UUID
    var step: Int  // Step position (0-based)
    var note: UInt8  // MIDI note 0-127
    var velocity: UInt8  // 1-127
    var duration: Double  // In steps (1.0 = full step, 0.5 = half)
}

enum TriggerMode: String, Codable {
    case oneShot, toggle, momentary
}

enum LaunchQuantize: String, Codable {
    case none, beat, bar
}
```

### Pattern 3: Canvas-Based Grid for Performance
**What:** SwiftUI Canvas for 60fps grid rendering
**When to use:** Piano roll and step grid with many cells
**Example:**
```swift
// Source: SwiftUI Canvas documentation, performance patterns
struct PianoRollGridView: View {
    let pattern: Pattern
    let trackIndex: Int
    @Binding var selectedNotes: Set<UUID>

    var body: some View {
        Canvas { context, size in
            let cellWidth = size.width / CGFloat(pattern.stepCount)
            let cellHeight = size.height / 128.0  // Full MIDI range

            // Draw grid lines (batched for performance)
            drawGridLines(context: context, size: size, cellWidth: cellWidth, cellHeight: cellHeight)

            // Draw notes
            for note in pattern.tracks[trackIndex].notes {
                let rect = CGRect(
                    x: CGFloat(note.step) * cellWidth,
                    y: size.height - CGFloat(note.note + 1) * cellHeight,
                    width: cellWidth * CGFloat(note.duration),
                    height: cellHeight
                )

                let isSelected = selectedNotes.contains(note.id)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2),
                    with: .color(isSelected ? .blue : .green)
                )
            }
        }
        .drawingGroup()  // Metal-backed rendering
    }
}
```

### Pattern 4: MIDI File Export with MIDIKitSMF
**What:** Convert patterns to Standard MIDI Files
**When to use:** Export/import functionality
**Example:**
```swift
// Source: MIDIKitSMF documentation
import MIDIKitSMF

extension Pattern {
    func toMIDIFile(bpm: Double, ppq: UInt16 = 480) -> MIDIFile {
        var midiFile = MIDIFile(
            format: .multipleTracksSynchronous,
            timeBase: .musical(ticksPerQuarterNote: ppq)
        )

        // Tempo track
        let tempoTrack = MIDIFile.Chunk.Track(events: [
            .tempo(delta: .none, bpm: bpm)
        ])
        midiFile.chunks.append(.track(tempoTrack))

        // Note tracks
        for track in tracks {
            var events: [MIDIFileEvent] = []

            // Sort notes by step position
            let sortedNotes = track.notes.sorted { $0.step < $1.step }
            var currentTick: UInt32 = 0

            for note in sortedNotes {
                let noteTick = UInt32(note.step) * UInt32(ppq) / 4  // Assuming 16th notes
                let deltaTicks = noteTick - currentTick

                // Note On
                events.append(.noteOn(
                    delta: .ticks(deltaTicks),
                    note: UInt7(note.note),
                    velocity: .midi1(UInt7(note.velocity)),
                    channel: UInt4(track.channel - 1)  // Convert to 0-indexed
                ))

                // Note Off (after duration)
                let durationTicks = UInt32(note.duration * Double(ppq) / 4)
                events.append(.noteOff(
                    delta: .ticks(durationTicks),
                    note: UInt7(note.note),
                    velocity: .midi1(0),
                    channel: UInt4(track.channel - 1)
                ))

                currentTick = noteTick + durationTicks
            }

            midiFile.chunks.append(.track(MIDIFile.Chunk.Track(events: events)))
        }

        return midiFile
    }
}
```

### Anti-Patterns to Avoid
- **Main thread clock:** Never run MIDI clock timer on main thread - UI updates cause jitter
- **Timer (Foundation):** Avoid Timer class for MIDI clock - not precise enough, runloop dependent
- **Large Canvas redraws:** Don't redraw entire grid on every frame - use .drawingGroup() and differential updates
- **Synchronous file I/O:** Never load/save patterns on main thread - use background actors
- **Hardcoded PPQN:** Always support configurable PPQN (24/48/96) as per user decision

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MIDI file parsing | Custom SMF parser | MIDIKitSMF | Complex format with running status, variable length values, multiple formats |
| MIDI events | Raw bytes | MIDIKit MIDIEvent | Type-safe, MIDI 1.0/2.0 compatible, handles encoding |
| Grid rendering | UIView/CALayer | SwiftUI Canvas + drawingGroup() | Metal-backed, declarative, integrates with SwiftUI state |
| JSON serialization | Manual encoding | Codable protocol | Compiler-generated, handles nested types automatically |
| Timer scheduling | Custom mach_absolute_time loop | DispatchSourceTimer | OS-optimized, deadline-based, leeway control |
| Song Position calculation | Manual beat math | MIDIKit songPositionPointer(midiBeat:) | Correct encoding, UInt14 handling |

**Key insight:** MIDI timing looks simple (just send 0xF8 bytes) but achieving consistent timing requires careful thread management and the right timer APIs. MIDIKit handles the event encoding; your job is the timing loop.

## Common Pitfalls

### Pitfall 1: Main Thread MIDI Clock
**What goes wrong:** MIDI clock has audible tempo fluctuations and drift
**Why it happens:** UI updates, SwiftUI rendering, and gesture handling block main thread
**How to avoid:** Use dedicated DispatchQueue with .userInteractive QoS
**Warning signs:** Tempo varies by +/- 5 BPM or more, clock feels "drunk"

### Pitfall 2: Timer Leeway Misconfiguration
**What goes wrong:** DispatchSourceTimer fires at inconsistent intervals
**Why it happens:** Default leeway allows system to coalesce timer fires for power efficiency
**How to avoid:** Set leeway to .nanoseconds(0) for MIDI clock, accept higher power usage
**Warning signs:** Clock pulses cluster together, then gaps

### Pitfall 3: Audio Buffer Size Jitter
**What goes wrong:** Notes scheduled within an audio buffer have variable timing
**Why it happens:** Events arriving mid-buffer must wait for next buffer cycle
**How to avoid:** For this phase, accept buffer-level jitter (~5-10ms at 256 samples). Future: audio-thread scheduling
**Warning signs:** Notes feel "early" or "late" by small random amounts

### Pitfall 4: Codable Model Migration Failures
**What goes wrong:** App crashes or loses data when loading old patterns after model changes
**Why it happens:** Adding/removing/renaming Codable properties breaks decoding
**How to avoid:** Include version field, implement custom init(from:) with fallback values
**Warning signs:** Test loading patterns saved from previous app versions

### Pitfall 5: Grid Performance Degradation
**What goes wrong:** Step grid becomes sluggish with many notes (64 steps x 16 tracks)
**Why it happens:** SwiftUI recreates views for every state change without proper identity
**How to avoid:** Use Canvas for rendering, ForEach with id:, .drawingGroup() modifier
**Warning signs:** Frame rate drops below 30fps when scrolling/editing grid

### Pitfall 6: Channel Index Confusion
**What goes wrong:** Notes play on wrong MIDI channel
**Why it happens:** Mixing 0-indexed (MIDIKit) and 1-indexed (UI) channel representations
**How to avoid:** Follow established pattern: 0-indexed internally, convert at UI boundary (from Phase 3)
**Warning signs:** Channel 1 in UI sends to channel 0, channel 16 doesn't work

## Code Examples

Verified patterns from official sources:

### Sending MIDI Clock Events
```swift
// Source: MIDIKit MIDIEvent documentation
// Clock tick (0xF8) - send 24 times per quarter note
let clockEvent = MIDIEvent.timingClock()

// Start (0xFA) - begin playback from position 0
let startEvent = MIDIEvent.start()

// Continue (0xFB) - resume from current position
let continueEvent = MIDIEvent.continue()

// Stop (0xFC) - halt playback
let stopEvent = MIDIEvent.stop()

// Song Position Pointer (0xF2) - locate to beat position
// midiBeat = number of MIDI beats (1 beat = 6 MIDI clocks)
// For 24 PPQN: quarter note = 24 clocks = 4 MIDI beats
let sppEvent = MIDIEvent.songPositionPointer(midiBeat: UInt14(32))
```

### Clock Interval Calculation
```swift
// Source: MIDI specification, verified
// MIDI clock sends 24 pulses per quarter note (24 PPQN) at minimum
// Higher resolutions: 48 PPQN or 96 PPQN

func clockInterval(bpm: Double, ppqn: Int) -> TimeInterval {
    // Interval in seconds between clock pulses
    // = 60 seconds / (BPM * pulses per quarter note)
    return 60.0 / (bpm * Double(ppqn))
}

// Examples:
// 120 BPM, 24 PPQN: 60 / (120 * 24) = 0.02083s = 20.83ms
// 120 BPM, 48 PPQN: 60 / (120 * 48) = 0.01042s = 10.42ms
// 120 BPM, 96 PPQN: 60 / (120 * 96) = 0.00521s = 5.21ms
```

### Tap Tempo Implementation
```swift
// Source: Standard tap tempo algorithm
class TapTempo {
    private var tapTimes: [Date] = []
    private let maxTaps = 4
    private let tapTimeout: TimeInterval = 2.0

    func tap() -> Double? {
        let now = Date()

        // Reset if too long since last tap
        if let lastTap = tapTimes.last,
           now.timeIntervalSince(lastTap) > tapTimeout {
            tapTimes.removeAll()
        }

        tapTimes.append(now)

        // Keep only recent taps
        if tapTimes.count > maxTaps {
            tapTimes.removeFirst()
        }

        // Need at least 2 taps for interval
        guard tapTimes.count >= 2 else { return nil }

        // Calculate average interval
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i-1])
        }
        let avgInterval = totalInterval / Double(tapTimes.count - 1)

        // Convert to BPM
        return 60.0 / avgInterval
    }
}
```

### Pattern Persistence with Versioning
```swift
// Source: Swift Codable best practices
struct Pattern: Codable {
    static let currentVersion = 1

    let id: UUID
    var name: String
    var version: Int
    // ... other properties

    enum CodingKeys: String, CodingKey {
        case id, name, version, stepCount, tracks, swing
        case triggerMode, launchQuantize, colorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // Handle version migration
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1

        // Migrate from older versions if needed
        if version < Pattern.currentVersion {
            // Apply migrations
        }

        // ... decode other properties with defaults for missing fields
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSTimer for MIDI clock | DispatchSourceTimer | iOS 10+ (2016) | More precise, deadline-based |
| MIDIPacketList | MIDIEventList | iOS 14+ (2020) | MIDI 2.0 support, UMP format |
| UICollectionView grids | SwiftUI Canvas + LazyVGrid | iOS 15+ (2021) | Metal-backed rendering |
| Core Data for patterns | SwiftData | iOS 17+ (2023) | Declarative, better Swift integration |
| Combine for state | @Observable | iOS 17+ (2023) | Simpler observation |

**Deprecated/outdated:**
- **MIDIPacketListAdd**: Replaced by MIDIEventListAdd for MIDI 2.0 compatibility
- **Timer (Foundation)**: Not suitable for sub-10ms precision required by MIDI clock
- **MIDISend()**: Use MIDISendEventList() for iOS 14+

## Open Questions

Things that couldn't be fully resolved:

1. **External Sync Reception**
   - What we know: MIDIKit can receive timing clock events via input handlers
   - What's unclear: Best pattern for slaving to external clock while maintaining local playback sync
   - Recommendation: Implement master clock first; external sync can follow in Phase 5+

2. **Audio Thread vs DispatchSourceTimer**
   - What we know: Apple TN2169 recommends mach_wait_until() for sub-500us precision
   - What's unclear: Whether DispatchSourceTimer achieves acceptable jitter for MIDI clock
   - Recommendation: Start with DispatchSourceTimer, measure jitter, escalate to audio thread if needed

3. **SwiftData vs Codable for Patterns**
   - What we know: Both work; SwiftData has richer querying, Codable is simpler
   - What's unclear: SwiftData's overhead for 64 patterns with complex nested structures
   - Recommendation: Use Codable + FileManager initially (consistent with ProfileManager pattern), consider SwiftData migration later

4. **Swing Implementation**
   - What we know: Swing delays even-numbered steps by a percentage
   - What's unclear: Whether swing applies before or after PPQN resolution
   - Recommendation: Implement at playback time: swing affects when notes trigger, not grid display

## Sources

### Primary (HIGH confidence)
- MIDIKit 0.10.7 source code (local .build/checkouts/MIDIKit/) - System Real-Time events, MIDIKitSMF
- [Apple DispatchSourceTimer documentation](https://developer.apple.com/documentation/dispatch/dispatchsourcetimer)
- [Apple Technical Note TN2169: High Precision Timers](https://developer.apple.com/library/archive/technotes/tn2169/_index.html)

### Secondary (MEDIUM confidence)
- [MIDIKit GitHub releases](https://github.com/orchetect/MIDIKit/releases) - Version 0.10.7 features
- [SwiftUI Canvas performance patterns](https://ravi6997.medium.com/swiftuis-canvas-revolution-how-apple-s-new-drawing-api-is-transforming-ios-development-in-2025-ac0c1eb838df)
- [Modern CoreMIDI Event Handling](https://furnacecreek.org/blog/2024-04-06-modern-coremidi-event-handling-with-swift)

### Tertiary (LOW confidence)
- [The Spectacular Sync Engine](https://github.com/michaeltyson/TheSpectacularSyncEngine) - Obj-C reference, not directly usable
- [MOD WIGGLER MIDI Clock Jitter Tests](https://www.modwiggler.com/forum/viewtopic.php?t=183197) - Community discussion
- [Loopy Pro Forum MIDI sync discussions](https://forum.loopypro.com/discussion/33561/midi-sync-clock-from-ios-to-external-gear-2019)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - MIDIKit verified from local source, DispatchSourceTimer from Apple docs
- Architecture: MEDIUM - Patterns derived from best practices, not production-verified
- Pitfalls: MEDIUM - Gathered from multiple community sources, cross-referenced
- MIDI File export: HIGH - MIDIKitSMF API verified from source code

**Research date:** 2026-01-23
**Valid until:** 2026-02-23 (30 days - stable domain, MIDIKit updated monthly)
