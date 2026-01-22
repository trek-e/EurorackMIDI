import SwiftUI
import MIDIKitCore

/// 2-octave piano keyboard (C3-B4) with velocity-sensitive keys
struct PianoKeyboardView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared

    // White keys: C D E F G A B (repeated for 2 octaves)
    // MIDI notes 48-71 (C3-B4)
    private let whiteKeyNotes: [UInt7] = [
        48, 50, 52, 53, 55, 57, 59,  // C3-B3
        60, 62, 64, 65, 67, 69, 71   // C4-B4
    ]

    // Black keys with their positions
    // Pattern: C# D# _ F# G# A# _ (repeated)
    private let blackKeyNotes: [UInt7] = [
        49, 51, 54, 56, 58,          // C#3-A#3
        61, 63, 66, 68, 70           // C#4-A#4
    ]

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // White keys layer
                HStack(spacing: 2) {
                    ForEach(whiteKeyNotes, id: \.self) { note in
                        PianoKeyView(
                            note: note,
                            isBlackKey: false,
                            manager: manager
                        )
                    }
                }

                // Black keys layer (positioned on top)
                HStack(spacing: 0) {
                    ForEach(Array(blackKeyNotes.enumerated()), id: \.offset) { index, note in
                        PianoKeyView(
                            note: note,
                            isBlackKey: true,
                            manager: manager
                        )
                        .offset(x: blackKeyOffset(for: index))
                    }
                }
                .padding(.leading, blackKeyInitialOffset())
            }
            .padding()
        }
    }

    // MARK: - Helper Methods

    /// Calculate the offset for each black key based on its position
    private func blackKeyOffset(for index: Int) -> CGFloat {
        // Pattern within octave: C# D# _ F# G# A# _
        // Positions: 0, 1, skip, 2, 3, 4, skip
        let patternInOctave = index % 5
        let octaveNumber = index / 5

        // Base spacing between keys
        let whiteKeyWidth: CGFloat = 40
        let whiteKeySpacing: CGFloat = 2
        let blackKeyWidth: CGFloat = 28

        // Starting position for this black key within its octave
        var position: CGFloat

        switch patternInOctave {
        case 0:  // C#
            position = whiteKeyWidth + whiteKeySpacing - (blackKeyWidth / 2)
        case 1:  // D#
            position = 2 * (whiteKeyWidth + whiteKeySpacing) - (blackKeyWidth / 2)
        case 2:  // F#
            position = 3 * (whiteKeyWidth + whiteKeySpacing) - (blackKeyWidth / 2)
        case 3:  // G#
            position = 4 * (whiteKeyWidth + whiteKeySpacing) - (blackKeyWidth / 2)
        case 4:  // A#
            position = 5 * (whiteKeyWidth + whiteKeySpacing) - (blackKeyWidth / 2)
        default:
            position = 0
        }

        // Add octave offset (7 white keys per octave)
        let octaveOffset = CGFloat(octaveNumber) * 7 * (whiteKeyWidth + whiteKeySpacing)

        return octaveOffset + position
    }

    /// Initial offset for the black keys layer
    private func blackKeyInitialOffset() -> CGFloat {
        return 0
    }
}
