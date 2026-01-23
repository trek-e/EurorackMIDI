import SwiftUI
import MIDIKitCore
import MIDIKitIO

/// Compact keyboard for testing velocity settings (one octave: C4 to B4)
struct MiniKeyboardView: View {
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?
    let midiChannel: Int

    private let manager = MIDIConnectionManager.shared
    @State private var activeKey: Int? = nil
    @State private var lastVelocity: Int? = nil

    private let baseNote = 60 // C4

    // Key dimensions
    private let whiteW: CGFloat = 32
    private let whiteH: CGFloat = 70
    private let blackW: CGFloat = 20
    private let blackH: CGFloat = 42
    private let gap: CGFloat = 1

    // White keys: C=0, D=2, E=4, F=5, G=7, A=9, B=11
    private let whiteNotes = [0, 2, 4, 5, 7, 9, 11]

    // Black keys: (semitone, after which white key index)
    private let blackKeys: [(semitone: Int, afterIndex: Int)] = [
        (1, 0),  // C#
        (3, 1),  // D#
        (6, 3),  // F#
        (8, 4),  // G#
        (10, 5)  // A#
    ]

    var body: some View {
        VStack(spacing: 8) {
            if let velocity = lastVelocity {
                Text("Velocity: \(velocity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Fixed-size keyboard
            let totalWidth = CGFloat(whiteNotes.count) * whiteW + CGFloat(whiteNotes.count - 1) * gap

            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: gap) {
                    ForEach(whiteNotes, id: \.self) { semitone in
                        MiniWhiteKey(
                            note: baseNote + semitone,
                            isActive: activeKey == baseNote + semitone,
                            width: whiteW,
                            height: whiteH,
                            onPress: { triggerNote($0) },
                            onRelease: { releaseNote($0) },
                            setActive: { activeKey = $0 }
                        )
                    }
                }

                // Black keys
                ForEach(blackKeys, id: \.semitone) { key in
                    MiniBlackKey(
                        note: baseNote + key.semitone,
                        isActive: activeKey == baseNote + key.semitone,
                        width: blackW,
                        height: blackH,
                        onPress: { triggerNote($0) },
                        onRelease: { releaseNote($0) },
                        setActive: { activeKey = $0 }
                    )
                    .position(
                        x: CGFloat(key.afterIndex + 1) * (whiteW + gap) - gap / 2,
                        y: blackH / 2
                    )
                }
            }
            .frame(width: totalWidth, height: whiteH)
            .background(Color(white: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private func triggerNote(_ note: Int) {
        let velocity = velocityCurve.toMIDIVelocity(from: 0.7, fixedValue: fixedVelocity)
        lastVelocity = Int(velocity)
        try? manager.sendNoteOn(note: UInt7(clamping: note), velocity: velocity)
    }

    private func releaseNote(_ note: Int) {
        try? manager.sendNoteOff(note: UInt7(clamping: note))
    }
}

struct MiniWhiteKey: View {
    let note: Int
    let isActive: Bool
    let width: CGFloat
    let height: CGFloat
    let onPress: (Int) -> Void
    let onRelease: (Int) -> Void
    let setActive: (Int?) -> Void

    var body: some View {
        Rectangle()
            .fill(isActive ? Color.blue.opacity(0.3) : Color.white)
            .frame(width: width, height: height)
            .border(Color.gray.opacity(0.5), width: 0.5)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isActive {
                            setActive(note)
                            onPress(note)
                        }
                    }
                    .onEnded { _ in
                        onRelease(note)
                        setActive(nil)
                    }
            )
    }
}

struct MiniBlackKey: View {
    let note: Int
    let isActive: Bool
    let width: CGFloat
    let height: CGFloat
    let onPress: (Int) -> Void
    let onRelease: (Int) -> Void
    let setActive: (Int?) -> Void

    var body: some View {
        Rectangle()
            .fill(isActive ? Color.blue : Color.black)
            .frame(width: width, height: height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isActive {
                            setActive(note)
                            onPress(note)
                        }
                    }
                    .onEnded { _ in
                        onRelease(note)
                        setActive(nil)
                    }
            )
    }
}
