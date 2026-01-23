import Foundation

/// Calculates BPM from user tap intervals
///
/// Maintains a rolling window of tap times to calculate average tempo.
/// Resets if tap interval exceeds timeout threshold.
final class TapTempo {
    // MARK: - Properties

    /// Recent tap timestamps
    private var tapTimes: [Date] = []

    /// Maximum number of taps to average
    private let maxTaps: Int

    /// Timeout before tap sequence resets (seconds)
    private let tapTimeout: TimeInterval

    // MARK: - Initialization

    /// Create a tap tempo calculator
    /// - Parameters:
    ///   - maxTaps: Maximum taps to average (default: 4)
    ///   - tapTimeout: Seconds before reset (default: 2.0)
    init(maxTaps: Int = 4, tapTimeout: TimeInterval = 2.0) {
        self.maxTaps = maxTaps
        self.tapTimeout = tapTimeout
    }

    // MARK: - Methods

    /// Record a tap and return calculated BPM if available
    /// - Returns: Calculated BPM clamped to 20-300 range, or nil if insufficient taps
    func tap() -> Double? {
        let now = Date()

        // Reset if too long since last tap
        if let lastTap = tapTimes.last,
           now.timeIntervalSince(lastTap) > tapTimeout {
            tapTimes.removeAll()
        }

        tapTimes.append(now)

        // Keep only recent taps
        if tapTimes.count > maxTaps {
            tapTimes.removeFirst()
        }

        // Need at least 2 taps for interval
        guard tapTimes.count >= 2 else { return nil }

        // Calculate average interval
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i - 1])
        }
        let avgInterval = totalInterval / Double(tapTimes.count - 1)

        // Convert to BPM, clamped to valid range
        let bpm = 60.0 / avgInterval
        return max(20.0, min(300.0, bpm))
    }

    /// Reset tap history
    func reset() {
        tapTimes.removeAll()
    }

    /// Number of recorded taps (for UI feedback)
    var tapCount: Int {
        tapTimes.count
    }
}
