---
phase: 04-sequencing
plan: 02
subsystem: pattern-models
tags: [swift, codable, data-models, sequencer]

dependency-graph:
  requires: []
  provides: ["Pattern", "Track", "StepNote", "TriggerMode", "LaunchQuantize"]
  affects: ["04-03", "04-04", "04-05"]

tech-stack:
  added: []
  patterns: ["Codable with version migration", "Extension methods for manipulation"]

key-files:
  created:
    - Sources/Sequencer/Models/StepNote.swift
    - Sources/Sequencer/Models/Track.swift
    - Sources/Sequencer/Models/Pattern.swift
  modified: []

decisions:
  - id: "color-as-hex"
    choice: "Store color as hex string"
    rationale: "Codable compatibility - SwiftUI Color not directly Codable"
  - id: "1-indexed-channels"
    choice: "MIDI channel 1-16 (1-indexed)"
    rationale: "UI consistency - users expect channels 1-16"
  - id: "let-id"
    choice: "id as let constant"
    rationale: "Immutable identity - duplicate creates new ID via init"

metrics:
  duration: "2m 33s"
  completed: "2026-01-23"
---

# Phase 04 Plan 02: Pattern Models Summary

**One-liner:** Codable Pattern/Track/StepNote data models with version migration support for step sequencer persistence

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 8a9c0a3 | feat | Create StepNote and Track models |
| ab5a964 | feat | Create Pattern model with enums |
| 4d58e0c | feat | Add helper methods for pattern and track manipulation |

## What Was Built

### StepNote Model
- Step position (0-based index)
- MIDI note number (0-127)
- Velocity (1-127)
- Duration in steps (1.0 = full step)

### Track Model
- MIDI channel (1-16, 1-indexed for UI)
- Notes array (`[StepNote]`)
- Mute/solo/volume controls
- Track name for display
- Helper methods: `addNote`, `removeNote`, `note(at:)`, `clearNotes`, `shouldPlay`

### Pattern Model
- UUID identification with `let id`
- Name and color (hex string) for visual identification
- Step count (1-64) with presets [8, 16, 32, 64]
- Tracks array (`[Track]`)
- Swing amount (0.0-1.0)
- Trigger mode enum: oneShot, toggle, momentary
- Launch quantize enum: none, beat, bar
- Beats per bar (default 4)
- Created/modified timestamps
- Version field for future migrations
- Custom `init(from:)` decoder with fallback defaults
- Helper methods: `addTrack`, `removeTrack`, `duplicate`, `touch`, `anySoloed`

### Color Extension
- `Color(hex:)` initializer for SwiftUI Color from hex string
- Placeholder `toHex()` method

## Deviations from Plan

None - plan executed exactly as written.

## Technical Notes

- All models conform to Codable, Identifiable, Equatable
- Pattern uses custom decoder for version migration support
- Track's `shouldPlay(anySoloed:)` implements proper solo/mute logic
- Pattern's `duplicate()` creates new instance via init (id is immutable)
- Color stored as hex string for Codable compatibility

## Verification Results

- Build succeeds without warnings
- Pattern contains tracks property linking to Track
- Track contains notes property linking to StepNote
- All models conform to Codable
- TriggerMode and LaunchQuantize enums available with CaseIterable

## Next Plan Readiness

Ready for 04-03 (Pattern Manager) - models provide all necessary structures for:
- Pattern storage and retrieval
- Bank organization (4 banks of 16 patterns)
- Pattern persistence via Codable JSON encoding
