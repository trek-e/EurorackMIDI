import SwiftUI
import AlertToast
import MIDIKitCore

/// Main view with tab navigation for control surfaces
struct ContentView: View {
    @State private var manager = MIDIConnectionManager.shared
    @State private var toastManager = ToastManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PerformancePadsView()
                .tabItem {
                    Label("Pads", systemImage: "square.grid.3x3.fill")
                }
                .tag(0)

            PianoKeyboardView()
                .tabItem {
                    Label("Keyboard", systemImage: "pianokeys")
                }
                .tag(1)
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
        .alert("Restore Saved Settings?", isPresented: $manager.showRestoreSettingsPrompt) {
            Button("Restore") {
                manager.confirmRestoreSettings()
            }
            Button("Use Defaults", role: .cancel) {
                manager.declineRestoreSettings()
            }
        } message: {
            if let device = manager.pendingReconnectDevice {
                Text("Reconnected to \(device.displayName). Would you like to restore your saved settings?")
            }
        }
        .alert("Remember This Device?", isPresented: $manager.showRememberDevicePrompt) {
            Button("Remember") {
                manager.rememberCurrentDevice()
            }
            Button("Not Now", role: .cancel) {
                manager.declineRememberDevice()
            }
        } message: {
            if let device = manager.deviceToRemember {
                Text("Save settings for \(device.displayName) and automatically reconnect in the future?")
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
