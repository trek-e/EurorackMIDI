import Foundation
import CloudStorage
import SwiftUI
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    // MARK: - Device-specific profiles (UserDefaults)

    private var deviceProfilesCache: [Int32: DeviceProfile] = [:]

    /// Get profile for a specific device
    func profile(for deviceID: Int32) -> DeviceProfile {
        // Check cache first
        if let cached = deviceProfilesCache[deviceID] {
            return cached
        }

        // Load from UserDefaults
        let key = "device_\(deviceID)_profile"
        if let data = UserDefaults.standard.data(forKey: key),
           let profile = try? JSONDecoder().decode(DeviceProfile.self, from: data) {
            deviceProfilesCache[deviceID] = profile
            return profile
        }

        // Return default profile
        let defaultProfile = DeviceProfile(deviceUniqueID: deviceID)
        deviceProfilesCache[deviceID] = defaultProfile
        return defaultProfile
    }

    /// Save profile for a specific device
    func saveProfile(_ profile: DeviceProfile, for deviceID: Int32) {
        var updatedProfile = profile
        updatedProfile.modifiedAt = Date()

        // Update cache
        deviceProfilesCache[deviceID] = updatedProfile

        // Persist to UserDefaults
        let key = "device_\(deviceID)_profile"
        if let data = try? JSONEncoder().encode(updatedProfile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Named presets (iCloud via CloudStorage)

    @CloudStorage("namedPresets") private var presetsData: Data?

    var namedPresets: [NamedPreset] {
        get {
            guard let data = presetsData else { return [] }
            return (try? JSONDecoder().decode([NamedPreset].self, from: data)) ?? []
        }
        set {
            presetsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Create a new named preset from a device profile
    func createPreset(name: String, from profile: DeviceProfile, tag: PresetTag) {
        var presetProfile = profile
        // Clear device-specific fields
        presetProfile.deviceUniqueID = nil
        presetProfile.deviceDisplayName = nil
        presetProfile.userNickname = nil
        presetProfile.id = UUID() // New ID for preset

        let preset = NamedPreset(
            name: name,
            tag: tag,
            profile: presetProfile
        )

        var presets = namedPresets
        presets.append(preset)
        namedPresets = presets
    }

    /// Delete a named preset
    func deletePreset(id: UUID) {
        var presets = namedPresets
        presets.removeAll { $0.id == id }
        namedPresets = presets
    }

    /// Rename a preset
    func renamePreset(id: UUID, to name: String) {
        var presets = namedPresets
        if let index = presets.firstIndex(where: { $0.id == id }) {
            presets[index].name = name
            namedPresets = presets
        }
    }

    /// Apply a preset to a specific device
    func applyPreset(_ preset: NamedPreset, to deviceID: Int32) {
        let currentProfile = profile(for: deviceID)

        var updatedProfile = preset.profile
        // Preserve device identity
        updatedProfile.deviceUniqueID = deviceID
        updatedProfile.deviceDisplayName = currentProfile.deviceDisplayName
        updatedProfile.userNickname = currentProfile.userNickname
        updatedProfile.id = currentProfile.id

        saveProfile(updatedProfile, for: deviceID)
    }

    // MARK: - Last connected device tracking

    // Note: Using Int instead of Int32 for @AppStorage compatibility
    var lastConnectedDeviceID: Int32? {
        get {
            if let value = UserDefaults.standard.object(forKey: "lastConnectedDeviceID") as? Int {
                return Int32(value)
            }
            return nil
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(Int(value), forKey: "lastConnectedDeviceID")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastConnectedDeviceID")
            }
        }
    }

    var lastConnectedDeviceName: String? {
        get {
            UserDefaults.standard.string(forKey: "lastConnectedDeviceName")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastConnectedDeviceName")
        }
    }

    /// Remember last connected device
    func rememberDevice(id: Int32, name: String) {
        lastConnectedDeviceID = id
        lastConnectedDeviceName = name
    }

    /// Forget a device profile
    func forgetDevice(id: Int32) {
        // Clear saved profile
        let key = "device_\(id)_profile"
        UserDefaults.standard.removeObject(forKey: key)
        deviceProfilesCache.removeValue(forKey: id)

        // Clear last connected if it matches
        if lastConnectedDeviceID == id {
            lastConnectedDeviceID = nil
            lastConnectedDeviceName = nil
        }
    }

    private init() {}
}
