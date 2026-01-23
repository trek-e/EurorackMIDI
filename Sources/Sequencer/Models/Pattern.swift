import Foundation
import SwiftUI

/// How a pattern is triggered during performance
enum TriggerMode: String, Codable, CaseIterable {
    case oneShot    // Play once then stop
    case toggle     // Toggle on/off with each trigger
    case momentary  // Play while held, stop on release
}

/// When a pattern starts after being triggered
enum LaunchQuantize: String, Codable, CaseIterable {
    case none  // Start immediately
    case beat  // Start on next beat
    case bar   // Start on next bar (4 beats)
}

/// A musical pattern containing tracks of step notes
struct Pattern: Codable, Identifiable, Equatable {
    /// Schema version for future migrations
    static let currentVersion = 1
    var version: Int = Pattern.currentVersion

    let id: UUID
    /// User-assigned pattern name
    var name: String
    /// Color for visual identification (stored as hex string)
    var colorHex: String
    /// Number of steps in pattern (1-64)
    var stepCount: Int
    /// Tracks in this pattern (1-16)
    var tracks: [Track]
    /// Swing amount (0.0 = no swing, 1.0 = full triplet swing)
    var swing: Double
    /// How pattern is triggered in performance mode
    var triggerMode: TriggerMode
    /// When pattern starts after trigger
    var launchQuantize: LaunchQuantize
    /// Beats per bar for this pattern (typically 4)
    var beatsPerBar: Int

    // Metadata
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "New Pattern",
        colorHex: String = "4A90D9",  // Default blue
        stepCount: Int = 16,
        tracks: [Track] = [Track()],
        swing: Double = 0.0,
        triggerMode: TriggerMode = .toggle,
        launchQuantize: LaunchQuantize = .bar,
        beatsPerBar: Int = 4,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.stepCount = stepCount
        self.tracks = tracks
        self.swing = swing
        self.triggerMode = triggerMode
        self.launchQuantize = launchQuantize
        self.beatsPerBar = beatsPerBar
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Convert hex string to SwiftUI Color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// Create a pattern with default single track
    static func newPattern(name: String = "New Pattern") -> Pattern {
        Pattern(
            name: name,
            tracks: [Track(channel: 1, name: "Track 1")]
        )
    }

    // MARK: - Codable with Version Migration

    enum CodingKeys: String, CodingKey {
        case version, id, name, colorHex, stepCount, tracks, swing
        case triggerMode, launchQuantize, beatsPerBar, createdAt, modifiedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle version migration
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "4A90D9"
        stepCount = try container.decode(Int.self, forKey: .stepCount)
        tracks = try container.decode([Track].self, forKey: .tracks)
        swing = try container.decodeIfPresent(Double.self, forKey: .swing) ?? 0.0
        triggerMode = try container.decodeIfPresent(TriggerMode.self, forKey: .triggerMode) ?? .toggle
        launchQuantize = try container.decodeIfPresent(LaunchQuantize.self, forKey: .launchQuantize) ?? .bar
        beatsPerBar = try container.decodeIfPresent(Int.self, forKey: .beatsPerBar) ?? 4
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()

        // Apply migrations for older versions
        if version < Pattern.currentVersion {
            // Future migrations go here
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }

    func toHex() -> String {
        // SwiftUI Color doesn't expose RGB components directly in a cross-platform way
        // This is a placeholder - full implementation would use UIColor/NSColor
        "4A90D9"
    }
}
