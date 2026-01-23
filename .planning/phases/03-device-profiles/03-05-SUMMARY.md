---
phase: 03-device-profiles
plan: 05
subsystem: control-surfaces
tags: [swift, swiftui, velocity, midi, gap-closure]
requires:
  - phases: [03-device-profiles]
  - plans: [03-01, 03-02, 03-04]
provides:
  - Velocity curve transformation applied to all MIDI note output
  - PadButtonView sends velocity based on profile curve/fixed settings
  - WhiteKeyView and BlackKeyView send velocity based on profile settings
  - All control surfaces read from MIDIConnectionManager.currentProfile
affects:
  - future: [03-06]
    reason: Completes velocity integration, enables full profile testing
tech-stack:
  added: []
  patterns:
    - Profile settings propagated via computed properties
    - VelocityCurve.toMIDIVelocity() centralized transformation
key-files:
  created: []
  modified:
    - Sources/Views/ControlSurfaces/PadButtonView.swift
    - Sources/Views/ControlSurfaces/PianoKeyboardView.swift
    - Sources/Views/ControlSurfaces/PerformancePadsView.swift
decisions:
  - what: Use 1.0 as normalized input for touch screens
    why: Touch screens lack pressure sensitivity unlike hardware MIDI controllers
    impact: Future enhancement could add 3D Touch/Force Touch support
  - what: Velocity properties passed through view hierarchy
    why: SwiftUI pattern for configuration propagation
    impact: Clean dependency injection without global state
metrics:
  duration: 3min
  completed: 2026-01-23
---

# Phase 03 Plan 05: Wire Velocity Curves to Control Surfaces Summary

**One-liner:** Control surfaces now apply velocity curves from device profiles, transforming MIDI output based on soft/hard/linear/fixed settings

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-23T05:17:39Z
- **Completed:** 2026-01-23T05:20:59Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Eliminated all hardcoded velocity 100 values from control surfaces
- Velocity curve transformation applied to pads, white keys, and black keys
- Profile settings flow: currentProfile → computed properties → view hierarchy → MIDI output

## Task Commits

Each task was committed atomically:

1. **Task 1: Add velocity curve to PadButtonView** - `77d335e` (feat)
2. **Task 2: Add velocity curve to piano keyboard** - `e4722f3` (feat)
3. **Task 3: Wire velocity curve to performance pads** - `25525e6` (feat)

## Files Modified

- `Sources/Views/ControlSurfaces/PadButtonView.swift` - Added velocityCurve and fixedVelocity properties, replaced hardcoded velocity with toMIDIVelocity()
- `Sources/Views/ControlSurfaces/PianoKeyboardView.swift` - Added velocity properties to WhiteKeyView, BlackKeyView, PianoOctaveView, and PianoKeyboardView; wired profile → keyboard hierarchy
- `Sources/Views/ControlSurfaces/PerformancePadsView.swift` - Added computed properties to read from currentProfile, passed to PadButtonView

## Decisions Made

**1. Use 1.0 as normalized input for touch screens**
- Touch screens don't have pressure sensitivity like hardware MIDI controllers
- Using maximum normalized value ensures consistent behavior
- Future enhancement: Could add 3D Touch/Force Touch support to provide actual pressure values

**2. Velocity properties passed through view hierarchy**
- SwiftUI pattern for clean dependency injection
- Computed properties in parent views read from currentProfile
- Parameters passed down to child views explicitly
- Avoids global state, makes data flow visible

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward implementation following existing patterns.

## Next Phase Readiness

**Gap closure progress:** This was the first of two gap closure plans for Phase 03.

**Ready for:**
- Plan 03-06 (final gap closure) can now test full profile integration
- Phase 04 sequencing features can rely on working velocity curves

**Blockers:** None

**What's working:**
- All control surfaces respect profile velocity settings
- Soft/Hard/Linear curves transform MIDI output
- Fixed velocity mode sends configured value
- Profile changes immediately affect MIDI output

**Next step:** Plan 03-06 will integrate remaining profile settings (pad mapping modes, octave offsets) and create comprehensive verification tests.

---
*Phase: 03-device-profiles*
*Completed: 2026-01-23*
