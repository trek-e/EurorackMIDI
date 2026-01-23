---
phase: 04-sequencing
plan: 03
subsystem: pattern-storage
tags: [persistence, CloudStorage, FileManager, patterns, banks]

dependency-graph:
  requires: ["04-02"]
  provides: ["PatternManager", "PatternBank", "pattern-persistence"]
  affects: ["04-05", "04-06"]

tech-stack:
  added: []
  patterns: ["CloudStorage-backup", "ObservableObject-singleton", "bank-slot-organization"]

key-files:
  created:
    - Sources/Sequencer/Models/PatternBank.swift
    - Sources/Sequencer/Managers/PatternManager.swift

decisions:
  - id: dual-storage
    choice: "CloudStorage + FileManager backup"
    reason: "Consistent with ProfileManager pattern, provides redundancy"
  - id: bank-organization
    choice: "4 banks of 16 slots (64 total patterns)"
    reason: "Per 04-CONTEXT requirements, matches hardware performance patterns"
  - id: observable-object
    choice: "ObservableObject over @Observable"
    reason: "CloudStorage compatibility requires ObservableObject"

metrics:
  duration: "4.5 min"
  completed: "2026-01-23"
  commits: 3
---

# Phase 04 Plan 03: Pattern Manager Summary

**One-liner:** PatternManager with CloudStorage+FileManager persistence organizing 64 patterns in 4 banks of 16 slots

## What Was Built

### PatternBank Model
- `PatternBank` struct organizing up to 16 patterns per bank
- 4 banks total (A, B, C, D) - 64 pattern slots
- Optional `Pattern?` array supporting empty slots
- Helper methods: `pattern(at:)`, `setPattern(_:at:)`, `firstEmptySlot`, `patternCount`
- Bank letter helper for display (A, B, C, D)

### PatternManager Singleton
- `ObservableObject` for SwiftUI integration
- `@CloudStorage("patternBanks")` for iCloud sync
- FileManager backup in Documents/Patterns/banks.json
- Published properties: `banks`, `selectedBankIndex`, `currentPattern`

### Pattern Operations
- **Save:** `savePattern(_:bank:slot:)` with auto-touch
- **Load:** `loadPattern(bank:slot:)`
- **Delete:** `deletePattern(bank:slot:)`
- **Move:** `movePattern(from:to:)`
- **Duplicate:** `duplicatePattern(bank:slot:)` returns new slot location
- **Auto-save:** `savePatternToFirstAvailable(_:)` finds first empty slot

### Search and Filter
- `searchPatterns(name:)` - case-insensitive name search
- `allPatterns()` - all non-empty patterns with location
- `recentPatterns(limit:)` - sorted by modification date

### Import/Export
- `exportPattern(bank:slot:)` - single pattern JSON
- `importPattern(from:)` - decode pattern from JSON
- `exportAllBanks()` - full backup
- `importBanks(from:)` - restore from backup

### Display Helpers
- `slotDisplayName(bank:slot:)` - pattern name or "Empty"
- `isSlotEmpty(bank:slot:)` - check availability
- `slotIdentifier(bank:slot:)` - "A1", "B16" style identifiers

## Key Files

| File | Purpose |
|------|---------|
| `Sources/Sequencer/Models/PatternBank.swift` | Bank structure for organizing patterns |
| `Sources/Sequencer/Managers/PatternManager.swift` | Pattern storage and persistence manager |

## Commits

| Hash | Description |
|------|-------------|
| b7077b3 | feat(04-03): add PatternBank model for organizing patterns |
| 2c8fa6a | feat(04-03): add PatternManager for pattern persistence |
| 6c6f3bb | feat(04-03): add pattern search and export helpers |

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **Dual storage strategy:** CloudStorage primary with FileManager backup
   - Matches ProfileManager pattern established in earlier phases
   - Provides redundancy if CloudStorage unavailable

2. **Bank organization:** 4 banks x 16 slots = 64 patterns
   - Per 04-CONTEXT requirements
   - Matches hardware pattern bank conventions

3. **ObservableObject:** Used over @Observable
   - Required for CloudStorage compatibility
   - Consistent with ProfileManager approach

## Technical Notes

- Pattern persistence uses same encoder/decoder as Pattern model
- Banks array always maintained at 4 elements
- Empty slots represented as `nil` in `[Pattern?]` array
- `persistBanks()` called after every mutation
- `loadBanks()` prefers CloudStorage, falls back to local file

## Dependencies Used

- `CloudStorage` package (already in project)
- `Foundation` FileManager
- `Pattern` model from 04-02

## Next Phase Readiness

Ready for:
- **04-05:** Step sequencer grid (can display patterns from banks)
- **04-06:** Pattern chaining (can access patterns via PatternManager)

No blockers identified.
