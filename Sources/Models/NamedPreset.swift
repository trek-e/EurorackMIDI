import Foundation

/// Tag categories for organizing presets
enum PresetTag: String, Codable, CaseIterable {
    case drums = "Drums"
    case keys = "Keys"
    case performance = "Performance"
    case custom = "Custom"

    var displayName: String {
        rawValue
    }
}

/// A named preset that can be applied to any device
struct NamedPreset: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var tag: PresetTag
    var profile: DeviceProfile
    var createdAt: Date = Date()
}
