import SwiftUI
import MIDIKitCore

/// Single-octave piano keyboard (13 keys: 8 white + 5 black)
/// Pattern: C C# D D# E F F# G G# A A# B C
struct PianoKeyboardView: View {
    @State private var manager = MIDIConnectionManager.shared
    @State private var profileManager = ProfileManager.shared
    @State private var octaveOffset: Int = 0

    private let baseOctave: Int = 4

    private var baseNote: Int {
        12 * (baseOctave + octaveOffset)
    }

    private var velocityCurve: VelocityCurve {
        manager.currentProfile?.velocityCurve ?? .linear
    }

    private var fixedVelocity: Int? {
        manager.currentProfile?.fixedVelocity
    }

    var body: some View {
        VStack(spacing: 16) {
            OctaveControlsView(
                octaveOffset: $octaveOffset,
                baseOctave: baseOctave,
                octaveSpan: 1
            )
            .padding(.horizontal)

            // Piano keyboard
            HStack {
                Spacer()
                PianoOctaveView(
                    baseNote: baseNote,
                    manager: manager,
                    velocityCurve: velocityCurve,
                    fixedVelocity: fixedVelocity
                )
                Spacer()
            }
            .padding()

            Spacer()
        }
        .onAppear {
            // Load octave offset from profile on appear
            if let device = manager.selectedDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                octaveOffset = profile.keyboardOctaveOffset
            }
        }
        .onChange(of: manager.selectedDevice) { _, newDevice in
            // Reload octave offset when device changes
            if let device = newDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                octaveOffset = profile.keyboardOctaveOffset
            }
        }
        .onChange(of: octaveOffset) { _, newOffset in
            // Save octave offset to profile when changed
            guard let device = manager.selectedDevice else { return }
            var profile = profileManager.profile(for: device.uniqueID)
            profile.keyboardOctaveOffset = newOffset
            profileManager.saveProfile(profile, for: device.uniqueID)
        }
    }
}

/// A single octave of piano keys (C to C, 13 keys)
struct PianoOctaveView: View {
    let baseNote: Int
    let manager: MIDIConnectionManager
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?

    // Key dimensions
    private let whiteW: CGFloat = 40
    private let whiteH: CGFloat = 150
    private let blackW: CGFloat = 24
    private let blackH: CGFloat = 90
    private let gap: CGFloat = 2

    // White key semitones: C=0, D=2, E=4, F=5, G=7, A=9, B=11, C=12
    private let whiteNotes = [0, 2, 4, 5, 7, 9, 11, 12]

    // Black key positions: (semitone, x position as fraction of white key width from left edge)
    // C#=1 between C-D, D#=3 between D-E, F#=6 between F-G, G#=8 between G-A, A#=10 between A-B
    private let blackKeys: [(semitone: Int, whiteIndex: Int)] = [
        (1, 0),   // C# after white key 0 (C)
        (3, 1),   // D# after white key 1 (D)
        (6, 3),   // F# after white key 3 (F)
        (8, 4),   // G# after white key 4 (G)
        (10, 5)   // A# after white key 5 (A)
    ]

    var body: some View {
        let totalWidth = CGFloat(whiteNotes.count) * whiteW + CGFloat(whiteNotes.count - 1) * gap

        ZStack(alignment: .topLeading) {
            // White keys
            HStack(spacing: gap) {
                ForEach(whiteNotes, id: \.self) { semitone in
                    WhiteKeyView(
                        note: UInt7(baseNote + semitone),
                        manager: manager,
                        width: whiteW,
                        height: whiteH,
                        velocityCurve: velocityCurve,
                        fixedVelocity: fixedVelocity
                    )
                }
            }

            // Black keys positioned on top
            ForEach(blackKeys, id: \.semitone) { key in
                BlackKeyView(
                    note: UInt7(baseNote + key.semitone),
                    manager: manager,
                    width: blackW,
                    height: blackH,
                    velocityCurve: velocityCurve,
                    fixedVelocity: fixedVelocity
                )
                .position(
                    x: CGFloat(key.whiteIndex + 1) * (whiteW + gap) - gap / 2,
                    y: blackH / 2
                )
            }
        }
        .frame(width: totalWidth, height: whiteH)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// White piano key
struct WhiteKeyView: View {
    let note: UInt7
    let manager: MIDIConnectionManager
    let width: CGFloat
    let height: CGFloat
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?

    @State private var isPressed = false

    var body: some View {
        Rectangle()
            .fill(isPressed ? Color.blue.opacity(0.3) : Color.white)
            .frame(width: width, height: height)
            .border(Color.gray.opacity(0.3), width: 1)
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

/// Black piano key
struct BlackKeyView: View {
    let note: UInt7
    let manager: MIDIConnectionManager
    let width: CGFloat
    let height: CGFloat
    let velocityCurve: VelocityCurve
    let fixedVelocity: Int?

    @State private var isPressed = false

    var body: some View {
        Rectangle()
            .fill(isPressed ? Color.blue : Color.black)
            .frame(width: width, height: height)
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
