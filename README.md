# Eurorack MIDI Controller

A USB MIDI controller app for macOS and iOS that connects to Eurorack modules. Built with SwiftUI and MIDIKit.

## Status: Alpha

This project is in active development. Currently implementing core features.

## Project Progress

```
Progress: [████████░░] 80% complete (8/10 phases)
```

### Milestone v1.0 Roadmap

| Phase | Name | Status | Plans | Description |
|-------|------|--------|-------|-------------|
| 1 | MIDI Foundation | Complete | 2/2 | USB MIDI connectivity and device management |
| 2 | Control Surfaces | Complete | 2/2 | Piano keyboard and performance pad interfaces |
| 3 | Device Profiles | Complete | 6/6 | Save/load configurations and auto-reconnect |
| 4 | Sequencing | Not Started | 0/? | Pattern creation, MIDI clock, and performance recall |

### Current Position

**Phase 3 Complete** - Device Profiles fully implemented with:
- Device profile persistence (MIDI channel, velocity curves, pad mapping)
- Auto-reconnect to last connected device on launch
- Settings UI with iOS Settings-style grouped sections
- Named presets with export/import JSON
- Velocity curve configuration with live preview
- Pad mapping modes (GM Drum, Chromatic, Custom)
- Octave controls that persist across sessions

### What's Next

**Phase 4: Sequencing** - Pattern composition and performance with tempo sync

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

### Planned (Phase 4)

- MIDI clock output with tempo control
- Step sequencer for pattern creation
- Pattern save/recall
- Performance mode with pattern triggering

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
└── Utilities/
    └── ProfileDocument.swift        # JSON export/import
```

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0).

See [LICENSE](LICENSE) for details.

## Author

Tom Boucher

---

*Built with SwiftUI and [MIDIKit](https://github.com/orchetect/MIDIKit)*
