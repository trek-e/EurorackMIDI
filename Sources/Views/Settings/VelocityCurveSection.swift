import SwiftUI

/// Velocity curve configuration section with visual preview and testing
struct VelocityCurveSection: View {
    @Binding var velocityCurve: VelocityCurve
    @Binding var fixedVelocity: Int?
    let midiChannel: Int

    var body: some View {
        Section {
            // Curve picker
            Picker("Curve", selection: $velocityCurve) {
                ForEach(VelocityCurve.allCases, id: \.self) { curve in
                    Text(curve.displayName).tag(curve)
                }
            }
            .onChange(of: velocityCurve) { _, newValue in
                if newValue == .fixed && fixedVelocity == nil {
                    fixedVelocity = 64 // Default to mid velocity
                }
            }

            // Fixed velocity stepper (only shown for .fixed curve)
            if velocityCurve == .fixed {
                Stepper("Fixed Value: \(fixedVelocity ?? 64)", value: Binding(
                    get: { fixedVelocity ?? 64 },
                    set: { fixedVelocity = $0 }
                ), in: 1...127)
            }

            // Visual curve preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Curve Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                CurvePreviewView(curve: velocityCurve)
                    .frame(height: 80)
                    .padding(.vertical, 4)
            }

            // Mini keyboard for live testing
            VStack(alignment: .leading, spacing: 4) {
                Text("Test Keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                MiniKeyboardView(
                    velocityCurve: velocityCurve,
                    fixedVelocity: fixedVelocity,
                    midiChannel: midiChannel
                )
                .padding(.vertical, 4)
            }
        } header: {
            Text("Velocity")
        }
    }
}

/// Visual representation of velocity curve
struct CurvePreviewView: View {
    let curve: VelocityCurve

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                // Plot the curve
                path.move(to: CGPoint(x: 0, y: height))

                for x in stride(from: 0, through: width, by: 1) {
                    let normalizedInput = x / width
                    let output = curve.apply(to: normalizedInput)
                    let y = height - (output * height)

                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 2)

            // Reference lines
            Path { path in
                // Horizontal mid-line
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))

                // Vertical mid-line
                path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)

            // Labels
            VStack {
                HStack {
                    Text("127")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("1")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}
