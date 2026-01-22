import SwiftUI
import MIDIKitCore

/// 4x4 grid of performance pads for triggering MIDI notes
struct PerformancePadsView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared

    // Define adaptive grid columns (adjusts from 2-4 columns based on screen size)
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 150), spacing: 8)
    ]

    // Standard General MIDI drum mapping: notes 36-51 (16 pads)
    private let notes: [UInt7] = Array(36...51)

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                PadButtonView(
                    note: note,
                    label: "Pad \(index + 1)",
                    manager: manager
                )
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding()
    }
}
