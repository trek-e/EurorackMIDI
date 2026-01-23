import SwiftUI
import MIDIKitCore

/// 4x4 grid of performance pads for triggering MIDI notes
struct PerformancePadsView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared
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

    /// Notes array based on current octave offset
    /// Standard General MIDI drum mapping: notes 36-51 by default
    private var notes: [UInt7] {
        let baseNote = UInt7(12 * (baseOctave + octaveOffset))  // C of the base octave
        return (0..<padCount).map { UInt7($0) + baseNote }
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
    }
}
