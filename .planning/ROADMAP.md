# EurorackMIDI Roadmap

## Project Goal

Create a SwiftUI MIDI controller app for iOS that connects to Eurorack modular synthesizers via USB MIDI, providing performance pads, keyboard, and step sequencer with tempo sync.

---

## Phase 1: MIDI Foundation
**Goal**: Establish USB MIDI connectivity with device selection and hot-plug support
**Status**: COMPLETE
**Plans**: 2 plans
- [x] 01-01-PLAN.md - MIDI connection manager with hot-plug detection
- [x] 01-02-PLAN.md - Note on/off messaging and channel selection

---

## Phase 2: Control Surfaces
**Goal**: Implement performance pads and piano keyboard with touch input
**Status**: COMPLETE
**Plans**: 2 plans
- [x] 02-01-PLAN.md - Performance pads with velocity curves
- [x] 02-02-PLAN.md - Piano keyboard with octave controls

---

## Phase 3: Device Profiles
**Goal**: Save and load device-specific configurations
**Status**: COMPLETE
**Plans**: 6 plans (including gap closure)
- [x] 03-01-PLAN.md - Device profile data model
- [x] 03-02-PLAN.md - Profile persistence and CloudStorage
- [x] 03-03-PLAN.md - Settings UI with profile management
- [x] 03-04-PLAN.md - Velocity curve settings (gap closure)
- [x] 03-05-PLAN.md - Velocity curve integration (gap closure)
- [x] 03-06-PLAN.md - Octave offset persistence (gap closure)

---

## Phase 4: Sequencing
**Goal**: Enable pattern composition and performance with tempo sync
**Depends on**: Phase 3
**Requirements**: SEQ-01, SEQ-02, SEQ-03, SEQ-04
**Success Criteria** (what must be TRUE):
  1. App outputs MIDI clock at user-specified tempo for Eurorack module sync
  2. User can create note patterns using tap-to-place grid interface
  3. User can save created patterns/compositions for later use
  4. User can recall saved patterns during performance via pad interface
  5. MIDI clock maintains stable tempo without drift or jitter
**Status**: PLANNED
**Plans**: 6 plans

Plans:
- [ ] 04-01-PLAN.md - MIDI clock engine with tap tempo
- [ ] 04-02-PLAN.md - Pattern data models (Pattern, Track, StepNote)
- [ ] 04-03-PLAN.md - Pattern storage manager with banks
- [ ] 04-04-PLAN.md - Transport controls UI
- [ ] 04-05-PLAN.md - Piano roll grid for note editing
- [ ] 04-06-PLAN.md - Pattern playback engine and browser

---

## Completed Milestones

| Phase | Plans | Completion |
|-------|-------|------------|
| 1 - MIDI Foundation | 2 | 100% |
| 2 - Control Surfaces | 2 | 100% |
| 3 - Device Profiles | 6 | 100% |
| 4 - Sequencing | 0/6 | 0% |

---

*Last updated: 2026-01-23*
