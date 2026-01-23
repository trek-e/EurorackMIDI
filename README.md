# Eurorack MIDI Controller

A USB MIDI controller app for macOS and iOS that connects to Eurorack modules. Built with SwiftUI and MIDIKit.

## Status: Alpha

This project is in active development. Currently implementing core features.

## Project Progress

```
Progress: [██████████] 100% complete (4/4 phases)
```

### Milestone v1.0 Roadmap

| Phase | Name | Status | Plans | Description |
|-------|------|--------|-------|-------------|
| 1 | MIDI Foundation | Complete | 2/2 | USB MIDI connectivity and device management |
| 2 | Control Surfaces | Complete | 2/2 | Piano keyboard and performance pad interfaces |
| 3 | Device Profiles | Complete | 6/6 | Save/load configurations and auto-reconnect |
| 4 | Sequencing | Complete | 6/6 | Pattern creation, MIDI clock, and performance recall |

### Current Position

**All 4 Phases Complete** - v1.0 Milestone achieved with:
- USB MIDI connectivity and device management
- Piano keyboard and performance pad interfaces
- Device profiles with auto-reconnect and persistence
- Step sequencer with MIDI clock, pattern creation, and performance triggering

### What's New in Phase 4

- MIDI clock output at 20-300 BPM with 24/48/96 PPQN
- Tap tempo for live BPM input
- Piano roll step sequencer with tap-to-place notes
- 64 patterns organized in 4 banks of 16 slots
- Pattern browser with performance pad triggering
- Track mute/solo/volume controls

## Features

### Implemented

- USB MIDI device discovery and connection (macOS/iOS)
- Hot-plug detection for devices connected after launch
- MIDI channel selection (1-16)
- Piano keyboard with touch/mouse input
- 16-pad performance grid with touch/click triggering
- Velocity curves (Linear, Soft, Hard, Exponential, Fixed)
- Pad mapping modes (GM Drum, Chromatic from base note, Custom)
- Device profiles with automatic persistence
- Named presets with JSON export/import
- Auto-reconnect on app launch
- Cross-platform support (iOS 17+, macOS 14+)

### Implemented (Phase 4)

- MIDI clock output with tempo control (20-300 BPM, tap tempo)
- Step sequencer with piano roll grid (tap-to-place notes)
- Pattern storage in 4 banks of 16 slots
- Pattern browser with performance pad triggering
- Three clock modes: auto, manual, always running
- Track mute/solo/volume controls
- Swing and launch quantization per pattern

## Requirements

- iOS 17.0+ or macOS 14.0+
- Xcode 15.0+
- USB MIDI device (iOS requires Camera Connection Kit or USB-C adapter)

## Building

1. Clone the repository
2. Open `EurorackMIDI.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run (Cmd+R)

## Architecture

```
Sources/
├── App/
│   └── EurorackMIDIApp.swift       # App entry point
├── Managers/
│   ├── MIDIConnectionManager.swift  # MIDI device handling
│   ├── ProfileManager.swift         # Profile persistence
│   └── ToastManager.swift           # User feedback
├── Models/
│   ├── DeviceProfile.swift          # Device configuration
│   ├── VelocityCurve.swift          # Velocity transformations
│   ├── PadMappingMode.swift         # Pad note mapping
│   └── NamedPreset.swift            # Preset storage
├── Views/
│   ├── ContentView.swift            # Main tab view
│   ├── DevicePickerView.swift       # Device selection
│   ├── ControlSurfaces/
│   │   ├── PianoKeyboardView.swift  # Piano keyboard
│   │   ├── PerformancePadsView.swift # 16-pad grid
│   │   └── OctaveControlsView.swift # Octave +/- controls
│   └── Settings/
│       ├── DeviceSettingsView.swift # Settings sheet
│       ├── VelocityCurveSection.swift
│       ├── PadMappingSection.swift
│       └── PresetListView.swift
├── Utilities/
│   └── ProfileDocument.swift        # JSON export/import
└── Sequencer/
    ├── Engine/
    │   ├── ClockEngine.swift        # MIDI clock generation
    │   ├── SequencerEngine.swift    # Pattern playback
    │   └── TapTempo.swift           # Tap tempo calculation
    ├── Managers/
    │   └── PatternManager.swift     # Pattern storage
    ├── Models/
    │   ├── Pattern.swift            # Pattern data model
    │   ├── Track.swift              # Track with notes
    │   ├── StepNote.swift           # Individual note
    │   ├── PatternBank.swift        # Bank organization
    │   └── TransportState.swift     # Play/stop state
    └── Views/
        ├── TransportView.swift      # Tempo/playback controls
        ├── SequencerView.swift      # Main sequencer UI
        ├── PianoRollGridView.swift  # Note grid editor
        └── PatternBrowserView.swift # Pattern selection
```

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0).

See [LICENSE](LICENSE) for details.

## Author

Tom Boucher

---

*Built with SwiftUI and [MIDIKit](https://github.com/orchetect/MIDIKit)*
