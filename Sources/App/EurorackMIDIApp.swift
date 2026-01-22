import SwiftUI

@main
struct EurorackMIDIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Eurorack MIDI Controller")
            .padding()
    }
}
