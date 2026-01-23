import Foundation

/// Determines how performance pads are mapped to MIDI notes
enum PadMappingMode: String, Codable, CaseIterable {
    case gmDrum
    case chromaticBase
    case custom

    var displayName: String {
        switch self {
        case .gmDrum:
            return "GM Drums"
        case .chromaticBase:
            return "Chromatic"
        case .custom:
            return "Custom"
        }
    }
}
