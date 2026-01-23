import SwiftUI

@main
struct EurorackMIDIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Auto-reconnect after short delay to allow MIDI system to initialize
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        await MIDIConnectionManager.shared.attemptAutoReconnect()
                    }
                }
        }
    }
}
