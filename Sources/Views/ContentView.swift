import SwiftUI
import AlertToast
import MIDIKitCore

/// Main view with tab navigation for control surfaces
struct ContentView: View {
    @State private var manager = MIDIConnectionManager.shared
    @State private var toastManager = ToastManager.shared
    @State private var profileManager = ProfileManager.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
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
            .navigationTitle("EurorackMIDI")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    DevicePickerView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ChannelSelectorView()
                }
                #else
                ToolbarItem(placement: .automatic) {
                    DevicePickerView()
                }
                ToolbarItem(placement: .automatic) {
                    ChannelSelectorView()
                }
                #endif
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
        .onAppear {
            // Load default tab from profile if device is selected
            if let device = manager.selectedDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                selectedTab = profile.defaultTab
            }
        }
        .onChange(of: manager.selectedDevice) { _, newDevice in
            // Load default tab when device changes
            if let device = newDevice {
                let profile = profileManager.profile(for: device.uniqueID)
                selectedTab = profile.defaultTab
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
