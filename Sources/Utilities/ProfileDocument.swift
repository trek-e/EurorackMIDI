import Foundation
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

/// Utility for exporting/importing device profiles as JSON
struct ProfileDocument {
    /// Export a profile to JSON data
    static func exportProfile(_ profile: DeviceProfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(profile)
    }

    /// Import a profile from JSON data
    static func importProfile(from data: Data) throws -> DeviceProfile {
        let decoder = JSONDecoder()
        return try decoder.decode(DeviceProfile.self, from: data)
    }

    /// Generate a filename for a profile export
    static func filename(for profile: DeviceProfile) -> String {
        let deviceName = profile.userNickname ?? profile.deviceDisplayName ?? "Device"
        let sanitized = deviceName.replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        return "\(sanitized)_\(timestamp).json"
    }

    #if os(iOS)
    /// Share profile JSON using UIActivityViewController
    static func shareProfile(_ profile: DeviceProfile, from sourceView: UIView) throws {
        let data = try exportProfile(profile)
        let filename = self.filename(for: profile)

        // Write to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tempURL)

        // Present share sheet
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        // For iPad popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        // Present from root view controller
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    #endif
}
