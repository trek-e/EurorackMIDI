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
