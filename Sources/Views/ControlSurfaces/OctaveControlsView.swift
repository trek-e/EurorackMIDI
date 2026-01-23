import SwiftUI

/// Reusable octave control widget with +/- buttons and range display
struct OctaveControlsView: View {
    // MARK: - Properties

    @Binding var octaveOffset: Int
    let baseOctave: Int
    let octaveSpan: Int
    let minOctave: Int
    let maxOctave: Int

    // MARK: - Initialization

    init(
        octaveOffset: Binding<Int>,
        baseOctave: Int,
        octaveSpan: Int,
        minOctave: Int = 0,
        maxOctave: Int = 8
    ) {
        self._octaveOffset = octaveOffset
        self.baseOctave = baseOctave
        self.octaveSpan = octaveSpan
        self.minOctave = minOctave
        self.maxOctave = maxOctave
    }

    // MARK: - Computed Properties

    /// Current lowest octave number
    private var currentStartOctave: Int {
        baseOctave + octaveOffset
    }

    /// Current highest octave number
    private var currentEndOctave: Int {
        currentStartOctave + octaveSpan - 1
    }

    /// Text representation of current octave range (e.g., "C3-B4")
    private var rangeText: String {
        let startNoteName = noteNameForOctave(currentStartOctave)
        let endNoteName = noteNameForOctave(currentEndOctave, lastNote: true)
        return "\(startNoteName)-\(endNoteName)"
    }

    /// Can we decrease the octave offset?
    private var canDecreaseOctave: Bool {
        currentStartOctave > minOctave
    }

    /// Can we increase the octave offset?
    private var canIncreaseOctave: Bool {
        currentEndOctave < maxOctave
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            // Decrease octave button
            Button {
                octaveOffset -= 1
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(canDecreaseOctave ? .blue : .gray)
            }
            .disabled(!canDecreaseOctave)

            // Range display
            Text(rangeText)
                .font(.headline)
                .monospacedDigit()
                .frame(minWidth: 80)

            // Increase octave button
            Button {
                octaveOffset += 1
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(canIncreaseOctave ? .blue : .gray)
            }
            .disabled(!canIncreaseOctave)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helper Methods

    /// Generate note name for given octave
    /// - Parameters:
    ///   - octave: The octave number (0-8)
    ///   - lastNote: If true, returns "B" (last note of octave), otherwise "C" (first note)
    /// - Returns: Note name with octave (e.g., "C3" or "B4")
    private func noteNameForOctave(_ octave: Int, lastNote: Bool = false) -> String {
        let noteName = lastNote ? "B" : "C"
        return "\(noteName)\(octave)"
    }
}
