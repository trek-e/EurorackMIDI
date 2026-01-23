---
phase: "04-sequencing"
plan: "01"
subsystem: "sequencer-engine"
tags: ["midi-clock", "dispatch-timer", "transport", "tap-tempo"]

dependency_graph:
  requires: ["03-device-profiles"]
  provides: ["clock-engine", "transport-state", "tap-tempo"]
  affects: ["04-02", "04-03", "04-04"]

tech_stack:
  added: []
  patterns:
    - "DispatchSourceTimer for precision timing"
    - "@Observable clock engine for UI binding"
    - "Clock mode enum for auto/manual/always behavior"

key_files:
  created:
    - "Sources/Sequencer/Engine/ClockEngine.swift"
    - "Sources/Sequencer/Engine/TapTempo.swift"
    - "Sources/Sequencer/Models/TransportState.swift"
  modified:
    - "Sources/Managers/MIDIConnectionManager.swift"

decisions:
  - id: "04-01-clock-timing"
    decision: "DispatchSourceTimer with zero leeway"
    rationale: "Provides deadline-based scheduling with nanosecond precision for MIDI clock"
  - id: "04-01-clock-modes"
    decision: "Three clock modes: auto, manual, always"
    rationale: "Matches user decisions from 04-CONTEXT.md for flexible sync scenarios"
  - id: "04-01-mainactor"
    decision: "@MainActor ClockEngine with background timer queue"
    rationale: "UI properties on main thread, timer on dedicated high-priority queue"

metrics:
  duration: "3 min"
  completed: "2026-01-23"
---

# Phase 04 Plan 01: Clock Engine Summary

DispatchSourceTimer-based MIDI clock generator with transport control, tap tempo, and three clock modes (auto/manual/always) for Eurorack sync.

## Task Completion

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create transport state and clock engine foundation | c10e904 | TransportState.swift, ClockEngine.swift, MIDIConnectionManager.swift |
| 2 | Add tap tempo and BPM configuration | 6f8ea4b | TapTempo.swift, ClockEngine.swift |
| 3 | Add clock mode and song position pointer support | aa442a6 | ClockEngine.swift |

## Deviations from Plan

None - plan executed exactly as written.

## Technical Notes

### Clock Engine Architecture
- Uses `DispatchSourceTimer` on dedicated `userInteractive` QoS queue
- Timer leeway set to `.nanoseconds(0)` for maximum precision
- `@Observable` class for SwiftUI binding of bpm, transportState, isClockRunning
- `@MainActor` isolated for UI safety, timer callbacks on background queue

### Clock Interval Calculation
```
interval = 60.0 / (bpm * ppqn) seconds
120 BPM @ 24 PPQN = 20.83ms between clock pulses
120 BPM @ 48 PPQN = 10.42ms
120 BPM @ 96 PPQN = 5.21ms
```

### MIDI Events Sent
- `.timingClock()` - 0xF8 on each tick
- `.start()` - 0xFA when transport starts
- `.stop()` - 0xFC when transport stops
- `.continue()` - 0xFB when resuming from pause
- `.songPositionPointer(midiBeat:)` - 0xF2 for position sync

### Tap Tempo Algorithm
- Rolling average of 2-4 tap intervals
- 2-second timeout resets tap history
- BPM clamped to 20-300 range

## What's Ready for Next Plans

The clock engine provides the foundation for:
- **04-02 (Pattern Models)**: Patterns will reference clock tempo for playback
- **04-03 (Sequencer Engine)**: Will use ClockEngine.tick() callback for note scheduling
- **04-04 (Transport UI)**: UI can observe bpm, transportState, isClockRunning

## Integration Points

**MIDIConnectionManager** now exposes:
```swift
func sendSystemRealTime(event: MIDIEvent) throws
```

**ClockEngine** provides:
```swift
var bpm: Double           // 20-300, observed by UI
var ppqn: Int             // 24, 48, or 96
var transportState: TransportState
var clockMode: ClockMode
var isClockRunning: Bool
func start() / stop() / continue_()
func processTap() -> Double?
func sendSongPositionPointer()
```

---
*Completed: 2026-01-23*
