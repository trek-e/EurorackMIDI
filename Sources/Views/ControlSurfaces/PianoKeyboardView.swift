import SwiftUI
import MIDIKitCore

/// Single-octave piano keyboard (13 keys: 8 white + 5 black)
/// Pattern: C C# D D# E F F# G G# A A# B C
struct PianoKeyboardView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared
    @State private var octaveOffset: Int = 0

    // Layout constants - realistic piano key proportions
    private let whiteKeyWidth: CGFloat = 44
    private let whiteKeyHeight: CGFloat = 160
    private let whiteKeySpacing: CGFloat = 2
    private let blackKeyWidth: CGFloat = 26
    private let blackKeyHeight: CGFloat = 100

    // Keyboard configuration
    private let baseOctave: Int = 4  // Base octave C4 (middle C)

    // 8 white keys: C, D, E, F, G, A, B, C (includes octave)
    private let whiteKeyOffsets: [UInt7] = [0, 2, 4, 5, 7, 9, 11, 12]

    // 5 black keys with their positions (which white key they come after)
    // C#(after C), D#(after D), F#(after F), G#(after G), A#(after A)
    private let blackKeyData: [(semitone: UInt7, afterWhiteIndex: Int)] = [
        (1, 0),   // C# after C (index 0)
        (3, 1),   // D# after D (index 1)
        (6, 3),   // F# after F (index 3)
        (8, 4),   // G# after G (index 4)
        (10, 5)   // A# after A (index 5)
    ]

    // MARK: - Computed Properties

    private var baseNote: UInt7 {
        UInt7(12 * (baseOctave + octaveOffset))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Octave controls
            OctaveControlsView(
                octaveOffset: $octaveOffset,
                baseOctave: baseOctave,
                octaveSpan: 1
            )
            .padding(.horizontal)

            // Keyboard container - centered horizontally
            HStack {
                Spacer()

                // Piano keyboard using ZStack for layering
                ZStack(alignment: .topLeading) {
                    // White keys layer
                    HStack(spacing: whiteKeySpacing) {
                        ForEach(whiteKeyOffsets, id: \.self) { offset in
                            PianoKeyView(
                                note: baseNote + offset,
                                isBlackKey: false,
                                manager: manager,
                                whiteKeyWidth: whiteKeyWidth,
                                whiteKeyHeight: whiteKeyHeight,
                                blackKeyWidth: blackKeyWidth,
                                blackKeyHeight: blackKeyHeight
                            )
                        }
                    }

                    // Black keys layer - positioned absolutely
                    ForEach(blackKeyData, id: \.semitone) { data in
                        PianoKeyView(
                            note: baseNote + data.semitone,
                            isBlackKey: true,
                            manager: manager,
                            whiteKeyWidth: whiteKeyWidth,
                            whiteKeyHeight: whiteKeyHeight,
                            blackKeyWidth: blackKeyWidth,
                            blackKeyHeight: blackKeyHeight
                        )
                        .offset(x: blackKeyXOffset(afterWhiteIndex: data.afterWhiteIndex))
                    }
                }
                .padding(8)
                .background(Color(white: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding()

            Spacer()
        }
    }

    // MARK: - Helper Methods

    /// Calculate X offset for black key positioned after given white key index
    private func blackKeyXOffset(afterWhiteIndex: Int) -> CGFloat {
        let whiteKeyUnit = whiteKeyWidth + whiteKeySpacing
        // Position at the right edge of the white key, centered
        return whiteKeyUnit * CGFloat(afterWhiteIndex + 1) - (blackKeyWidth / 2) - (whiteKeySpacing / 2)
    }
}
