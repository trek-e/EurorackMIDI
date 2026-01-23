import SwiftUI
import MIDIKitCore
import MIDIKitIO

/// Compact keyboard for testing velocity settings
struct MiniKeyboardView: View {
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?
    let midiChannel: Int

    private let manager = MIDIConnectionManager.shared
    @State private var activeKey: Int? = nil
    @State private var lastVelocity: Int? = nil

    // 12 keys: C, C#, D, D#, E, F, F#, G, G#, A, A#, B (one octave starting at C4)
    private let baseNote = 60 // C4
    private let whiteKeys = [0, 2, 4, 5, 7, 9, 11] // C, D, E, F, G, A, B
    private let blackKeys = [1, 3, 6, 8, 10] // C#, D#, F#, G#, A#

    var body: some View {
        VStack(spacing: 8) {
            // Velocity indicator
            if let velocity = lastVelocity {
                Text("Velocity: \(velocity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Mini keyboard
            GeometryReader { geometry in
                ZStack {
                    // White keys
                    HStack(spacing: 1) {
                        ForEach(whiteKeys, id: \.self) { offset in
                            keyView(note: baseNote + offset, isBlack: false, width: geometry.size.width / 7)
                        }
                    }

                    // Black keys overlay
                    HStack(spacing: 0) {
                        ForEach(0..<7) { index in
                            let offset = whiteKeys[index]
                            if blackKeys.contains(offset + 1) {
                                HStack(spacing: 0) {
                                    Spacer()
                                        .frame(width: (geometry.size.width / 7) * 0.65)
                                    keyView(note: baseNote + offset + 1, isBlack: true, width: (geometry.size.width / 7) * 0.7)
                                        .zIndex(1)
                                    Spacer()
                                        .frame(width: (geometry.size.width / 7) * 0.65)
                                }
                            } else {
                                Spacer()
                                    .frame(width: geometry.size.width / 7)
                            }
                        }
                    }
                }
            }
            .frame(height: 80)
        }
    }

    private func keyView(note: Int, isBlack: Bool, width: CGFloat) -> some View {
        let isActive = activeKey == note

        return Rectangle()
            .fill(isBlack ? (isActive ? Color.gray : Color.black) : (isActive ? Color.blue.opacity(0.3) : Color.white))
            .overlay(
                Rectangle()
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(width: width, height: isBlack ? 50 : 80)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if activeKey != note {
                            activeKey = note
                            triggerNote(note, location: value.location, in: isBlack ? 50 : 80)
                        }
                    }
                    .onEnded { _ in
                        if activeKey == note {
                            releaseNote(note)
                            activeKey = nil
                        }
                    }
            )
    }

    private func triggerNote(_ note: Int, location: CGPoint, in height: CGFloat) {
        // Calculate velocity from vertical position (top = soft, bottom = hard)
        let normalizedInput = max(0.0, min(1.0, location.y / height))
        let velocity = velocityCurve.toMIDIVelocity(from: normalizedInput, fixedValue: fixedVelocity)

        lastVelocity = Int(velocity)

        // Send MIDI Note On
        try? manager.sendNoteOn(note: UInt7(clamping: note), velocity: velocity)
    }

    private func releaseNote(_ note: Int) {
        // Send MIDI Note Off
        try? manager.sendNoteOff(note: UInt7(clamping: note))
    }
}
