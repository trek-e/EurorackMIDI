import Foundation

/// A bank of patterns (up to 16 patterns per bank)
struct PatternBank: Codable, Identifiable {
    static let patternsPerBank = 16
    static let bankCount = 4

    let id: UUID
    /// Bank name (e.g., "Bank A", "Bank B")
    var name: String
    /// Bank index (0-3)
    let index: Int
    /// Patterns in this bank (up to 16, indexed 0-15)
    var patterns: [Pattern?]

    init(id: UUID = UUID(), name: String, index: Int) {
        self.id = id
        self.name = name
        self.index = index
        // Initialize with empty slots
        self.patterns = Array(repeating: nil, count: PatternBank.patternsPerBank)
    }

    /// Get pattern at slot (0-15)
    func pattern(at slot: Int) -> Pattern? {
        guard slot >= 0 && slot < patterns.count else { return nil }
        return patterns[slot]
    }

    /// Set pattern at slot (0-15)
    mutating func setPattern(_ pattern: Pattern?, at slot: Int) {
        guard slot >= 0 && slot < patterns.count else { return }
        patterns[slot] = pattern
    }

    /// Find first empty slot
    var firstEmptySlot: Int? {
        patterns.firstIndex(where: { $0 == nil })
    }

    /// Count of non-empty patterns
    var patternCount: Int {
        patterns.compactMap { $0 }.count
    }

    /// Bank letter (A, B, C, D)
    var letter: String {
        String(UnicodeScalar(65 + index)!)  // ASCII: A=65
    }
}

// MARK: - Default Banks
extension PatternBank {
    static func defaultBanks() -> [PatternBank] {
        (0..<bankCount).map { index in
            PatternBank(
                name: "Bank \(String(UnicodeScalar(65 + index)!))",
                index: index
            )
        }
    }
}
