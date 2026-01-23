import SwiftUI

/// Piano roll grid for editing step sequencer notes
struct PianoRollGridView: View {
    @Binding var track: Track
    let stepCount: Int

    // Display range (MIDI notes to show)
    @State private var lowestNote: UInt8 = 36  // C2
    @State private var visibleNoteRange: UInt8 = 24  // 2 octaves

    // Note editing state
    @State private var selectedNoteId: UUID?
    @State private var showNoteEditor: Bool = false

    // Sequencer engine for playhead position
    @State private var sequencerEngine = SequencerEngine.shared
    @ObservedObject private var clockEngine = ClockEngine.shared

    // Environment for color scheme adaptation
    @Environment(\.colorScheme) private var colorScheme

    // Grid configuration
    private let minCellWidth: CGFloat = 40
    private let cellHeight: CGFloat = 24
    private let pianoKeyWidth: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            // Octave controls
            octaveControls

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
        .sheet(isPresented: $showNoteEditor) {
            noteEditorSheet
        }
    }

    // MARK: - Octave Controls

    private var octaveControls: some View {
        HStack {
            Button {
                // Move down an octave (lower notes)
                if lowestNote >= 12 {
                    lowestNote -= 12
                }
            } label: {
                Label("Octave Down", systemImage: "chevron.down")
                    .labelStyle(.iconOnly)
            }
            .disabled(lowestNote < 12)

            Text("Octave: \(Int(lowestNote) / 12 - 1) - \(Int(lowestNote + visibleNoteRange - 1) / 12 - 1)")
                .font(.caption.monospacedDigit())
                .frame(minWidth: 80)

            Button {
                // Move up an octave (higher notes)
                if lowestNote + visibleNoteRange <= 115 {  // Keep top note <= 127
                    lowestNote += 12
                }
            } label: {
                Label("Octave Up", systemImage: "chevron.up")
                    .labelStyle(.iconOnly)
            }
            .disabled(lowestNote + visibleNoteRange > 115)

            Spacer()

            // Show current MIDI note range
            Text("MIDI: \(lowestNote) - \(lowestNote + visibleNoteRange - 1)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
    }

    // MARK: - Note Editor Sheet

    @ViewBuilder
    private var noteEditorSheet: some View {
        if let noteId = selectedNoteId,
           let noteIndex = track.notes.firstIndex(where: { $0.id == noteId }) {
            NoteEditorView(
                note: $track.notes[noteIndex],
                onDelete: {
                    track.removeNote(id: noteId)
                    showNoteEditor = false
                    selectedNoteId = nil
                }
            )
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

    // Computed properties to track for canvas updates
    private var isPlaying: Bool {
        clockEngine.transportState == .playing
    }

    private var playheadStep: Int {
        sequencerEngine.currentStep
    }

    private func gridCanvas(size: CGSize) -> some View {
        // Capture values for Canvas redraw tracking
        let currentPlayheadStep = playheadStep
        let playing = isPlaying

        return Canvas { context, canvasSize in
            let cellWidth = canvasSize.width / CGFloat(stepCount)

            // Draw grid lines
            drawGridLines(context: context, size: canvasSize, cellWidth: cellWidth)

            // Draw notes
            drawNotes(context: context, size: canvasSize, cellWidth: cellWidth)

            // Draw playhead if playing
            if playing {
                drawPlayhead(context: context, size: canvasSize, cellWidth: cellWidth, step: currentPlayheadStep)
            }
        }
        .id("grid-\(currentPlayheadStep)-\(playing)")  // Force redraw when playhead moves
        .drawingGroup()  // Metal-backed rendering
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTap(at: value.location, in: size)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { value in
                    switch value {
                    case .second(true, let drag):
                        if let location = drag?.location {
                            handleLongPress(at: location, in: size)
                        }
                    default:
                        break
                    }
                }
        )
    }

    // MARK: - Drawing

    private func drawGridLines(context: GraphicsContext, size: CGSize, cellWidth: CGFloat) {
        // Use adaptive colors based on color scheme
        let isDark = colorScheme == .dark
        let bgColor = isDark ? Color(white: 0.12) : Color(white: 0.95)
        let whiteKeyRowColor = isDark ? Color(white: 0.18) : Color(white: 1.0)
        let gridLineColor = isDark ? Color(white: 0.35) : Color(white: 0.7)
        let beatLineColor = isDark ? Color(white: 0.5) : Color(white: 0.5)

        // Fill background
        let bgRect = CGRect(origin: .zero, size: size)
        context.fill(Path(bgRect), with: .color(bgColor))

        // Shade white key rows (lighter in both modes)
        for row in 0..<Int(visibleNoteRange) {
            let y = CGFloat(row) * cellHeight
            let noteNumber = lowestNote + UInt8(Int(visibleNoteRange) - 1 - row)
            let isBlackKey = [1, 3, 6, 8, 10].contains(Int(noteNumber) % 12)

            if !isBlackKey {
                let rect = CGRect(x: 0, y: y, width: size.width, height: cellHeight)
                context.fill(Path(rect), with: .color(whiteKeyRowColor))
            }
        }

        // Vertical lines (step divisions)
        for step in 0...stepCount {
            let x = CGFloat(step) * cellWidth
            let isBeatLine = step % 4 == 0

            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))

            context.stroke(
                path,
                with: .color(isBeatLine ? beatLineColor : gridLineColor),
                lineWidth: isBeatLine ? 1.5 : 0.5
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
                with: .color(isC ? .blue.opacity(0.6) : gridLineColor),
                lineWidth: isC ? 1.5 : 0.5
            )
        }
    }

    private func drawPlayhead(context: GraphicsContext, size: CGSize, cellWidth: CGFloat, step: Int) {
        let x = CGFloat(step) * cellWidth

        // Highlight the current step column
        let columnRect = CGRect(x: x, y: 0, width: cellWidth, height: size.height)
        context.fill(Path(columnRect), with: .color(.orange.opacity(0.2)))

        // Draw playhead line at start of step
        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: size.height))

        // Bright orange playhead for visibility
        context.stroke(
            path,
            with: .color(.orange),
            lineWidth: 3
        )

        // Draw small triangle marker at top
        var triangle = Path()
        triangle.move(to: CGPoint(x: x, y: 0))
        triangle.addLine(to: CGPoint(x: x + 8, y: 12))
        triangle.addLine(to: CGPoint(x: x, y: 12))
        triangle.closeSubpath()
        context.fill(triangle, with: .color(.orange))
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

            // Note color based on velocity - blue to match pad theme
            let velocityAlpha = 0.6 + (Double(note.velocity) / 127.0) * 0.4
            let noteColor = Color.blue.opacity(velocityAlpha)

            context.fill(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(noteColor)
            )

            // Note border
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(.blue),
                lineWidth: 1.5
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

    private func handleLongPress(at location: CGPoint, in size: CGSize) {
        let cellWidth = size.width / CGFloat(stepCount)
        let step = Int(location.x / cellWidth)
        let row = Int(location.y / cellHeight)
        let noteNumber = lowestNote + visibleNoteRange - 1 - UInt8(row)

        // Find note at this position
        if let note = track.notes.first(where: { $0.step == step && $0.note == noteNumber }) {
            selectedNoteId = note.id
            showNoteEditor = true
        }
    }
}

// MARK: - Piano Key Label

struct PianoKeyLabel: View {
    let note: UInt8
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isBlackKey ? Color.black : Color.white)
                .border(Color.secondary.opacity(0.3), width: 0.5)

            Text(noteName)
                .font(.caption2)
                .fontWeight(note % 12 == 0 ? .bold : .regular)
                .foregroundColor(isBlackKey ? .white : .black)
        }
    }

    private var isBlackKey: Bool {
        [1, 3, 6, 8, 10].contains(Int(note) % 12)
    }

    private var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(note) / 12 - 1
        let name = noteNames[Int(note) % 12]
        return "\(name)\(octave)"
    }
}

// MARK: - Note Editor View

/// Sheet view for editing note velocity and duration
struct NoteEditorView: View {
    @Binding var note: StepNote
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Note") {
                    HStack {
                        Text("Pitch")
                        Spacer()
                        Text(noteName(for: note.note))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Step")
                        Spacer()
                        Text("\(note.step + 1)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Velocity") {
                    Slider(
                        value: Binding(
                            get: { Double(note.velocity) },
                            set: { note.velocity = UInt8($0) }
                        ),
                        in: 1...127,
                        step: 1
                    )
                    Text("\(note.velocity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Duration") {
                    Picker("Duration", selection: $note.duration) {
                        Text("1/4 step").tag(0.25)
                        Text("1/2 step").tag(0.5)
                        Text("1 step").tag(1.0)
                        Text("2 steps").tag(2.0)
                        Text("4 steps").tag(4.0)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Note")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }

    private func noteName(for midiNote: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(midiNote) / 12 - 1
        let noteName = noteNames[Int(midiNote) % 12]
        return "\(noteName)\(octave)"
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
