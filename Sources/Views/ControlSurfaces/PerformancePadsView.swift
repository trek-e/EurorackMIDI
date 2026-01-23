import SwiftUI
import MIDIKitCore

/// 4x4 grid of performance pads for triggering MIDI notes
struct PerformancePadsView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared
    @State private var profileManager = ProfileManager.shared
    @State private var octaveOffset: Int = 0

    // Define adaptive grid columns (adjusts from 2-4 columns based on screen size)
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 150), spacing: 8)
    ]

    // Pad configuration
    private let baseOctave: Int = 2  // Base octave C2 (MIDI note 36)
    private let padCount: Int = 16
    private let octaveSpan: Int = 2  // 16 pads span ~1.33 octaves, round up to 2 for display

    // MARK: - Computed Properties

    /// Notes array based on current octave offset and pad mapping mode
    private var notes: [UInt7] {
        guard let device = manager.selectedDevice else {
            // Default chromatic fallback
            let baseNote = UInt7(12 * (baseOctave + octaveOffset))
            return (0..<padCount).map { UInt7($0) + baseNote }
        }

        let profile = profileManager.profile(for: device.uniqueID)

        switch profile.padMappingMode {
        case .gmDrum:
            // GM Drum: Fixed notes 36-51 (Kick=36, Snare=38, etc.)
            // With octave offset applied
            let baseNote = UInt7(36 + (octaveOffset * 12))
            return (0..<padCount).map { UInt7($0) + baseNote }

        case .chromaticBase:
            // Chromatic from profile's padBaseNote
            let baseNote = UInt7(profile.padBaseNote + (octaveOffset * 12))
            return (0..<padCount).map { UInt7($0) + baseNote }

        case .custom:
            // Custom note mapping from profile (ignore octave offset for full control)
            if let customNotes = profile.customPadNotes, customNotes.count == padCount {
                return customNotes.map { UInt7(clamping: $0) }
            }
            // Fallback to chromatic if custom not configured
            let baseNote = UInt7(profile.padBaseNote + (octaveOffset * 12))
            return (0..<padCount).map { UInt7($0) + baseNote }
        }
    }

    private var velocityCurve: VelocityCurve {
        manager.currentProfile?.velocityCurve ?? .linear
    }

    private var fixedVelocity: Int? {
        manager.currentProfile?.fixedVelocity
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Octave controls
            OctaveControlsView(
                octaveOffset: $octaveOffset,
                baseOctave: baseOctave,
                octaveSpan: octaveSpan
            )
            .padding(.horizontal)
            .padding(.top, 8)

            // Pads grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    PadButtonView(
                        note: note,
                        label: "Pad \(index + 1)",
                        manager: manager,
                        velocityCurve: velocityCurve,
                        fixedVelocity: fixedVelocity
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding()
        }
        .onAppear {
            // Load octave offset from profile on appear
            if let device = manager.selectedDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                octaveOffset = profile.padOctaveOffset
            }
        }
        .onChange(of: manager.selectedDevice) { _, newDevice in
            // Reload octave offset when device changes
            if let device = newDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                octaveOffset = profile.padOctaveOffset
            }
        }
        .onChange(of: octaveOffset) { _, newOffset in
            // Save octave offset to profile when changed
            guard let device = manager.selectedDevice else { return }
            var profile = profileManager.profile(for: device.uniqueID)
            profile.padOctaveOffset = newOffset
            profileManager.saveProfile(profile, for: device.uniqueID)
        }
    }
}
