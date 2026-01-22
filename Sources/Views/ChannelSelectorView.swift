import SwiftUI
import MIDIKitCore

/// MIDI channel selector (1-16)
struct ChannelSelectorView: View {
    @State private var manager = MIDIConnectionManager.shared

    var body: some View {
        Picker("Channel", selection: $manager.selectedChannel) {
            ForEach(1...16, id: \.self) { channel in
                Text("Ch \(channel)")
                    .tag(MIDIChannel(channel - 1))
            }
        }
        .pickerStyle(.menu)
    }
}
