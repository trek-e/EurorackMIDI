import XCTest
@testable import EurorackMIDILib

final class DeviceProfileTests: XCTestCase {
    func testDefaultValues() {
        let profile = DeviceProfile()

        XCTAssertEqual(profile.version, 1)
        XCTAssertNotNil(profile.id)
        XCTAssertNil(profile.deviceUniqueID)
        XCTAssertNil(profile.deviceDisplayName)
        XCTAssertNil(profile.userNickname)
        XCTAssertEqual(profile.midiChannel, 1)
        XCTAssertEqual(profile.keyboardOctaveOffset, 0)
        XCTAssertEqual(profile.padOctaveOffset, 0)
        XCTAssertEqual(profile.defaultTab, 0)
        XCTAssertEqual(profile.velocityCurve, .linear)
        XCTAssertNil(profile.fixedVelocity)
        XCTAssertEqual(profile.padMappingMode, .gmDrum)
        XCTAssertEqual(profile.padBaseNote, 36)
        XCTAssertNil(profile.customPadNotes)
    }

    func testEncodeDecode() throws {
        let original = DeviceProfile(
            deviceUniqueID: 12345,
            deviceDisplayName: "Test Device",
            userNickname: "My Synth",
            midiChannel: 5,
            keyboardOctaveOffset: 2,
            padOctaveOffset: -1,
            defaultTab: 1,
            velocityCurve: .soft,
            fixedVelocity: 100,
            padMappingMode: .chromaticBase,
            padBaseNote: 48,
            customPadNotes: [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84, 86]
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeviceProfile.self, from: data)

        // Verify all fields preserved
        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.deviceUniqueID, original.deviceUniqueID)
        XCTAssertEqual(decoded.deviceDisplayName, original.deviceDisplayName)
        XCTAssertEqual(decoded.userNickname, original.userNickname)
        XCTAssertEqual(decoded.midiChannel, original.midiChannel)
        XCTAssertEqual(decoded.keyboardOctaveOffset, original.keyboardOctaveOffset)
        XCTAssertEqual(decoded.padOctaveOffset, original.padOctaveOffset)
        XCTAssertEqual(decoded.defaultTab, original.defaultTab)
        XCTAssertEqual(decoded.velocityCurve, original.velocityCurve)
        XCTAssertEqual(decoded.fixedVelocity, original.fixedVelocity)
        XCTAssertEqual(decoded.padMappingMode, original.padMappingMode)
        XCTAssertEqual(decoded.padBaseNote, original.padBaseNote)
        XCTAssertEqual(decoded.customPadNotes, original.customPadNotes)
    }

    func testVersionFieldExists() throws {
        let profile = DeviceProfile()
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["version"], "Version field must exist for future migrations")
        XCTAssertEqual(json["version"] as? Int, 1)
    }

    func testNamedPresetEncodeDecode() throws {
        let profile = DeviceProfile(midiChannel: 10, velocityCurve: .hard)
        let original = NamedPreset(
            name: "Test Preset",
            tag: .drums,
            profile: profile
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NamedPreset.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.tag, original.tag)
        XCTAssertEqual(decoded.profile.midiChannel, original.profile.midiChannel)
        XCTAssertEqual(decoded.profile.velocityCurve, original.profile.velocityCurve)
    }

    func testPresetTagValues() {
        XCTAssertEqual(PresetTag.drums.displayName, "Drums")
        XCTAssertEqual(PresetTag.keys.displayName, "Keys")
        XCTAssertEqual(PresetTag.performance.displayName, "Performance")

        XCTAssertEqual(PresetTag.allCases.count, 4)
    }

    func testPadMappingModeValues() {
        XCTAssertEqual(PadMappingMode.gmDrum.displayName, "GM Drums")
        XCTAssertEqual(PadMappingMode.chromaticBase.displayName, "Chromatic")
        XCTAssertEqual(PadMappingMode.custom.displayName, "Custom")

        XCTAssertEqual(PadMappingMode.allCases.count, 3)
    }
}
