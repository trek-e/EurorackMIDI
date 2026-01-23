import SwiftUI
import MIDIKitCore

/// Individual piano key with velocity-sensitive MIDI output
struct PianoKeyView: View {
    // MARK: - Properties

    let note: UInt7
    let isBlackKey: Bool
    let manager: MIDIConnectionManager
    var whiteKeyWidth: CGFloat = 50
    var whiteKeyHeight: CGFloat = 180
    var blackKeyWidth: CGFloat = 32
    var blackKeyHeight: CGFloat = 110

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(keyColor)
            .frame(
                width: isBlackKey ? blackKeyWidth : whiteKeyWidth,
                height: isBlackKey ? blackKeyHeight : whiteKeyHeight
            )
            .overlay(
                RoundedRectangle(cornerRadius: isBlackKey ? 0 : 6)
                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: isBlackKey ? 4 : 6,
                    bottomTrailingRadius: isBlackKey ? 4 : 6,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.3), radius: isBlackKey ? 2 : 1, y: isBlackKey ? 2 : 1)
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

    private var keyColor: Color {
        if isPressed {
            return isBlackKey ? Color.blue.opacity(0.8) : Color.blue.opacity(0.3)
        }
        return isBlackKey ? Color.black : Color.white
    }
}
