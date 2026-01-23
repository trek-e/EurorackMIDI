import SwiftUI
import MIDIKitCore

/// Individual performance pad button with press/release MIDI triggering
struct PadButtonView: View {
    // MARK: - Properties

    let note: UInt7
    let label: String
    let manager: MIDIConnectionManager
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isPressed ? Color.orange : Color.blue)
                .shadow(
                    color: .black.opacity(0.3),
                    radius: isPressed ? 0 : 4,
                    x: 0,
                    y: isPressed ? 0 : 2
                )

            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(minWidth: 44, minHeight: 44) // Apple HIG accessibility minimum
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        try? manager.sendNoteOn(note: note, velocity: velocityCurve.toMIDIVelocity(from: 1.0, fixedValue: fixedVelocity))
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
