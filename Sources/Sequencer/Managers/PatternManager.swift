import Foundation
import SwiftUI
import CloudStorage
import os.log

private let logger = Logger(subsystem: "com.eurorack.midi", category: "PatternManager")

/// Manages pattern storage and persistence
class PatternManager: ObservableObject {
    static let shared = PatternManager()

    // MARK: - Published Properties

    /// All pattern banks
    @Published private(set) var banks: [PatternBank] = PatternBank.defaultBanks()

    /// Currently selected bank index
    @Published var selectedBankIndex: Int = 0

    /// Currently selected pattern (for editing)
    @Published var currentPattern: Pattern?

    // MARK: - Cloud Storage

    @CloudStorage("patternBanks") private var storedBanksData: Data?

    // MARK: - File Storage (backup)

    private let patternsDirectoryName = "Patterns"
    private let banksFileName = "banks.json"

    private var patternsDirectory: URL {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to temp directory if documents unavailable (should never happen)
            return FileManager.default.temporaryDirectory.appendingPathComponent(patternsDirectoryName)
        }
        return documentsPath.appendingPathComponent(patternsDirectoryName)
    }

    // MARK: - Initialization

    private init() {
        createPatternsDirectoryIfNeeded()
        loadBanks()
    }

    private func createPatternsDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(
                at: patternsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create patterns directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Bank Access

    /// Get currently selected bank
    var selectedBank: PatternBank {
        banks[selectedBankIndex]
    }

    /// Get bank by index
    func bank(at index: Int) -> PatternBank? {
        guard index >= 0 && index < banks.count else { return nil }
        return banks[index]
    }

    // MARK: - Pattern Operations

    /// Save pattern to specific bank and slot
    func savePattern(_ pattern: Pattern, bank bankIndex: Int, slot: Int) {
        guard bankIndex >= 0 && bankIndex < banks.count else { return }
        guard slot >= 0 && slot < PatternBank.patternsPerBank else { return }

        var updatedPattern = pattern
        updatedPattern.touch()

        banks[bankIndex].setPattern(updatedPattern, at: slot)
        persistBanks()
    }

    /// Save pattern to first available slot in current bank
    func savePatternToFirstAvailable(_ pattern: Pattern) -> (bank: Int, slot: Int)? {
        // Try current bank first
        if let slot = banks[selectedBankIndex].firstEmptySlot {
            savePattern(pattern, bank: selectedBankIndex, slot: slot)
            return (selectedBankIndex, slot)
        }

        // Try other banks
        for (bankIndex, bank) in banks.enumerated() {
            if let slot = bank.firstEmptySlot {
                savePattern(pattern, bank: bankIndex, slot: slot)
                return (bankIndex, slot)
            }
        }

        return nil  // All slots full
    }

    /// Load pattern from bank and slot
    func loadPattern(bank bankIndex: Int, slot: Int) -> Pattern? {
        bank(at: bankIndex)?.pattern(at: slot)
    }

    /// Delete pattern from bank and slot
    func deletePattern(bank bankIndex: Int, slot: Int) {
        guard bankIndex >= 0 && bankIndex < banks.count else { return }
        banks[bankIndex].setPattern(nil, at: slot)
        persistBanks()
    }

    /// Move pattern between slots
    func movePattern(from: (bank: Int, slot: Int), to: (bank: Int, slot: Int)) {
        guard let pattern = loadPattern(bank: from.bank, slot: from.slot) else { return }
        deletePattern(bank: from.bank, slot: from.slot)
        savePattern(pattern, bank: to.bank, slot: to.slot)
    }

    /// Duplicate pattern to first available slot
    func duplicatePattern(bank bankIndex: Int, slot: Int) -> (bank: Int, slot: Int)? {
        guard let original = loadPattern(bank: bankIndex, slot: slot) else { return nil }
        let copy = original.duplicate()
        return savePatternToFirstAvailable(copy)
    }

    // MARK: - Persistence

    private func persistBanks() {
        do {
            let data = try JSONEncoder().encode(banks)

            // Save to CloudStorage
            storedBanksData = data

            // Also save to local file as backup
            let fileURL = patternsDirectory.appendingPathComponent(banksFileName)
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to persist pattern banks: \(error.localizedDescription)")
        }
    }

    private func loadBanks() {
        // Try CloudStorage first
        if let data = storedBanksData,
           let loadedBanks = try? JSONDecoder().decode([PatternBank].self, from: data) {
            banks = loadedBanks
            return
        }

        // Fall back to local file
        let fileURL = patternsDirectory.appendingPathComponent(banksFileName)
        if let data = try? Data(contentsOf: fileURL),
           let loadedBanks = try? JSONDecoder().decode([PatternBank].self, from: data) {
            banks = loadedBanks
            return
        }

        // Use defaults if nothing found
        banks = PatternBank.defaultBanks()
    }

    /// Force reload from storage
    func reload() {
        loadBanks()
    }

    /// Get total pattern count across all banks
    var totalPatternCount: Int {
        banks.reduce(0) { $0 + $1.patternCount }
    }
}

// MARK: - Search and Filter

extension PatternManager {
    /// Find all patterns matching a name (case-insensitive)
    func searchPatterns(name: String) -> [(bank: Int, slot: Int, pattern: Pattern)] {
        var results: [(bank: Int, slot: Int, pattern: Pattern)] = []

        for (bankIndex, bank) in banks.enumerated() {
            for (slot, pattern) in bank.patterns.enumerated() {
                if let p = pattern,
                   p.name.localizedCaseInsensitiveContains(name) {
                    results.append((bankIndex, slot, p))
                }
            }
        }

        return results
    }

    /// Get all non-empty patterns
    func allPatterns() -> [(bank: Int, slot: Int, pattern: Pattern)] {
        var results: [(bank: Int, slot: Int, pattern: Pattern)] = []

        for (bankIndex, bank) in banks.enumerated() {
            for (slot, pattern) in bank.patterns.enumerated() {
                if let p = pattern {
                    results.append((bankIndex, slot, p))
                }
            }
        }

        return results
    }

    /// Get patterns sorted by modification date (most recent first)
    func recentPatterns(limit: Int = 10) -> [(bank: Int, slot: Int, pattern: Pattern)] {
        allPatterns()
            .sorted { $0.pattern.modifiedAt > $1.pattern.modifiedAt }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Import/Export Data

extension PatternManager {
    /// Export single pattern as JSON data
    func exportPattern(bank bankIndex: Int, slot: Int) -> Data? {
        guard let pattern = loadPattern(bank: bankIndex, slot: slot) else { return nil }
        return try? JSONEncoder().encode(pattern)
    }

    /// Import pattern from JSON data
    func importPattern(from data: Data) -> Pattern? {
        try? JSONDecoder().decode(Pattern.self, from: data)
    }

    /// Export all banks as JSON data (for backup)
    func exportAllBanks() -> Data? {
        try? JSONEncoder().encode(banks)
    }

    /// Import banks from JSON data (replaces all)
    func importBanks(from data: Data) -> Bool {
        guard let loadedBanks = try? JSONDecoder().decode([PatternBank].self, from: data) else {
            return false
        }
        banks = loadedBanks
        persistBanks()
        return true
    }
}

// MARK: - Slot Display Helpers

extension PatternManager {
    /// Get display name for slot (pattern name or "Empty")
    func slotDisplayName(bank bankIndex: Int, slot: Int) -> String {
        loadPattern(bank: bankIndex, slot: slot)?.name ?? "Empty"
    }

    /// Check if slot is empty
    func isSlotEmpty(bank bankIndex: Int, slot: Int) -> Bool {
        loadPattern(bank: bankIndex, slot: slot) == nil
    }

    /// Get slot identifier string (e.g., "A1", "B16")
    func slotIdentifier(bank bankIndex: Int, slot: Int) -> String {
        let bankLetter = String(UnicodeScalar(65 + bankIndex)!)
        return "\(bankLetter)\(slot + 1)"
    }
}
