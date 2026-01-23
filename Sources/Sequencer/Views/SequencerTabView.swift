import SwiftUI

/// Sequencer tab containing transport controls and step sequencer
struct SequencerTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Transport controls at the top
            TransportView()

            Divider()

            // Placeholder for step sequencer grid (added in later plan)
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Step Sequencer")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Pattern editor coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.15))
        }
    }
}
