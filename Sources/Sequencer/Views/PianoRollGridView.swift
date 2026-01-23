import SwiftUI

/// Piano roll grid for editing step sequencer notes
struct PianoRollGridView: View {
    @Binding var track: Track
    let stepCount: Int

    // Display range (MIDI notes to show)
    @State private var lowestNote: UInt8 = 36  // C2
    @State private var visibleNoteRange: UInt8 = 24  // 2 octaves

    // Grid configuration
    private let minCellWidth: CGFloat = 40
    private let cellHeight: CGFloat = 24
    private let pianoKeyWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Piano keys column
                pianoKeysView

                // Scrollable grid
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    gridCanvas(size: gridSize(for: geometry))
                        .frame(
                            width: gridSize(for: geometry).width,
                            height: gridSize(for: geometry).height
                        )
                }
            }
        }
    }

    // MARK: - Grid Size

    private func gridSize(for geometry: GeometryProxy) -> CGSize {
        let width = max(CGFloat(stepCount) * minCellWidth, geometry.size.width - pianoKeyWidth)
        let height = CGFloat(visibleNoteRange) * cellHeight
        return CGSize(width: width, height: height)
    }

    // MARK: - Piano Keys

    private var pianoKeysView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach((0..<Int(visibleNoteRange)).reversed(), id: \.self) { offset in
                    let noteNumber = lowestNote + UInt8(offset)
                    PianoKeyLabel(note: noteNumber)
                        .frame(width: pianoKeyWidth, height: cellHeight)
                }
            }
        }
    }

    // MARK: - Grid Canvas

    private func gridCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let cellWidth = canvasSize.width / CGFloat(stepCount)

            // Draw grid lines
            drawGridLines(context: context, size: canvasSize, cellWidth: cellWidth)

            // Draw notes
            drawNotes(context: context, size: canvasSize, cellWidth: cellWidth)
        }
        .drawingGroup()  // Metal-backed rendering
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTap(at: value.location, in: size)
                }
        )
    }

    // MARK: - Drawing

    private func drawGridLines(context: GraphicsContext, size: CGSize, cellWidth: CGFloat) {
        // Vertical lines (step divisions)
        for step in 0...stepCount {
            let x = CGFloat(step) * cellWidth
            let isBeatLine = step % 4 == 0

            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))

            context.stroke(
                path,
                with: .color(isBeatLine ? .gray : .gray.opacity(0.3)),
                lineWidth: isBeatLine ? 1 : 0.5
            )
        }

        // Horizontal lines (note divisions)
        for row in 0...Int(visibleNoteRange) {
            let y = CGFloat(row) * cellHeight
            let noteNumber = lowestNote + UInt8(Int(visibleNoteRange) - row)
            let isC = noteNumber % 12 == 0  // C notes

            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))

            context.stroke(
                path,
                with: .color(isC ? .blue.opacity(0.5) : .gray.opacity(0.2)),
                lineWidth: isC ? 1 : 0.5
            )

            // Shade black keys
            if [1, 3, 6, 8, 10].contains(Int(noteNumber) % 12) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: cellHeight)
                context.fill(Path(rect), with: .color(.black.opacity(0.05)))
            }
        }
    }

    private func drawNotes(context: GraphicsContext, size: CGSize, cellWidth: CGFloat) {
        for note in track.notes {
            // Check if note is in visible range
            guard note.note >= lowestNote && note.note < lowestNote + visibleNoteRange else { continue }

            let row = Int(lowestNote + visibleNoteRange - 1 - note.note)
            let rect = CGRect(
                x: CGFloat(note.step) * cellWidth + 2,
                y: CGFloat(row) * cellHeight + 2,
                width: cellWidth * CGFloat(note.duration) - 4,
                height: cellHeight - 4
            )

            // Note color based on velocity
            let velocityAlpha = Double(note.velocity) / 127.0
            let noteColor = Color.green.opacity(0.5 + velocityAlpha * 0.5)

            context.fill(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(noteColor)
            )

            // Note border
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(.green),
                lineWidth: 1
            )
        }
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint, in size: CGSize) {
        let cellWidth = size.width / CGFloat(stepCount)

        let step = Int(location.x / cellWidth)
        let row = Int(location.y / cellHeight)
        let noteNumber = lowestNote + visibleNoteRange - 1 - UInt8(row)

        guard step >= 0 && step < stepCount else { return }
        guard noteNumber >= lowestNote && noteNumber < lowestNote + visibleNoteRange else { return }

        // Toggle note: remove if exists, add if not
        if let existingNote = track.notes.first(where: { $0.step == step && $0.note == noteNumber }) {
            track.removeNote(id: existingNote.id)
        } else {
            let newNote = StepNote(step: step, note: noteNumber, velocity: 100, duration: 1.0)
            track.addNote(newNote)
        }
    }
}

// MARK: - Piano Key Label

struct PianoKeyLabel: View {
    let note: UInt8

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isBlackKey ? Color.black : Color.white)
                .border(Color.gray.opacity(0.3), width: 0.5)

            if note % 12 == 0 {  // C notes
                Text(noteName)
                    .font(.caption2)
                    .foregroundColor(isBlackKey ? .white : .black)
            }
        }
    }

    private var isBlackKey: Bool {
        [1, 3, 6, 8, 10].contains(Int(note) % 12)
    }

    private var noteName: String {
        let octave = Int(note) / 12 - 1
        return "C\(octave)"
    }
}

// MARK: - Preview

#if DEBUG
struct PianoRollGridView_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollGridView(track: .constant(Track(
            channel: 1,
            notes: [
                StepNote(step: 0, note: 60, velocity: 100, duration: 1.0),
                StepNote(step: 4, note: 62, velocity: 80, duration: 1.0),
                StepNote(step: 8, note: 64, velocity: 100, duration: 2.0)
            ]
        )), stepCount: 16)
        .frame(height: 300)
    }
}
#endif
