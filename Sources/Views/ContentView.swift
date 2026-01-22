import SwiftUI
import AlertToast
import MIDIKitCore

/// Main view with MIDI controls and test functionality
struct ContentView: View {
    @State private var manager = MIDIConnectionManager.shared
    @State private var toastManager = ToastManager.shared

    var body: some View {
        VStack(spacing: 20) {
            // Connection status indicator
            HStack {
                Circle()
                    .fill(manager.selectedDevice != nil ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)

                Text(manager.selectedDevice != nil ? "Connected" : "No Device")
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            Spacer()

            // Test button
            Button(action: testNote) {
                Label("Test Note", systemImage: "music.note")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(manager.selectedDevice != nil ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(manager.selectedDevice == nil)

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                DevicePickerView()
                ChannelSelectorView()
            }
        }
        .toast(isPresenting: $toastManager.showToast) {
            AlertToast(
                displayMode: .banner(.slide),
                type: alertToastType(for: toastManager.toastType),
                title: toastManager.toastMessage
            )
        }
    }

    private func testNote() {
        Task {
            do {
                try await manager.testConnection()
            } catch {
                toastManager.show(message: error.localizedDescription, type: .error)
            }
        }
    }

    private func alertToastType(for toastType: ToastType) -> AlertToast.AlertType {
        switch toastType {
        case .info:
            return .regular
        case .success:
            return .complete(.green)
        case .warning:
            return .systemImage("exclamationmark.triangle", .orange)
        case .error:
            return .error(.red)
        }
    }
}
