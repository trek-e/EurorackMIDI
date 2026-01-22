import SwiftUI
import MIDIKitCore

/// Individual piano key with velocity-sensitive MIDI output
struct PianoKeyView: View {
    // MARK: - Properties

    let note: UInt7
    let isBlackKey: Bool
    let manager: MIDIConnectionManager

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(isPressed ? Color.blue : (isBlackKey ? Color.black : Color.white))
            .frame(
                width: isBlackKey ? 28 : 40,
                height: isBlackKey ? 80 : 120
            )
            .overlay(
                Rectangle()
                    .strokeBorder(Color.black, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            // Calculate velocity from gesture speed
                            let speed = sqrt(
                                pow(value.velocity.width, 2) +
                                pow(value.velocity.height, 2)
                            )

                            // Normalize speed to 0-1 range
                            let normalizedSpeed = min(speed / 2000.0, 1.0)

                            // Map to MIDI velocity range (1-127)
                            let velocity = UInt7(max(normalizedSpeed * 126 + 1, 1))

                            try? manager.sendNoteOn(note: note, velocity: velocity)
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        try? manager.sendNoteOff(note: note)
                        isPressed = false
                    }
            )
    }
}
