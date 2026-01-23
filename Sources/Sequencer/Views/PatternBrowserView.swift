import SwiftUI

/// Grid view for browsing and selecting patterns from banks
struct PatternBrowserView: View {
    @ObservedObject private var patternManager = PatternManager.shared

    /// Callback returns Pattern AND its location for persistence tracking
    let onSelect: (Pattern, (bank: Int, slot: Int)) -> Void

    @State private var selectedBankIndex: Int = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // Bank tabs
            bankTabBar

            Divider()

            // Pattern grid
            ScrollView {
                patternGrid
                    .padding()
            }
        }
    }

    // MARK: - Bank Tab Bar

    private var bankTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<PatternBank.bankCount, id: \.self) { index in
                Button {
                    selectedBankIndex = index
                } label: {
                    Text("Bank \(patternManager.banks[index].letter)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedBankIndex == index ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedBankIndex == index ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.secondary.opacity(0.1))
    }

    // MARK: - Pattern Grid

    private var patternGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<PatternBank.patternsPerBank, id: \.self) { slot in
                PatternSlotButton(
                    pattern: patternManager.loadPattern(bank: selectedBankIndex, slot: slot),
                    slotLabel: patternManager.slotIdentifier(bank: selectedBankIndex, slot: slot),
                    onTap: {
                        if let pattern = patternManager.loadPattern(bank: selectedBankIndex, slot: slot) {
                            // Return pattern AND location tuple
                            onSelect(pattern, (bank: selectedBankIndex, slot: slot))
                        }
                    },
                    onLongPress: {
                        // Could show context menu for delete/duplicate
                    }
                )
            }
        }
    }
}

// MARK: - Pattern Slot Button

struct PatternSlotButton: View {
    let pattern: Pattern?
    let slotLabel: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Slot number
                Text(slotLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Pattern indicator
                RoundedRectangle(cornerRadius: 8)
                    .fill(pattern?.color ?? Color.secondary.opacity(0.2))
                    .frame(height: 50)
                    .overlay(
                        Group {
                            if pattern == nil {
                                Image(systemName: "plus")
                                    .foregroundColor(.secondary)
                            }
                        }
                    )

                // Pattern name
                Text(pattern?.name ?? "Empty")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(pattern != nil ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(pattern == nil)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

// MARK: - Pattern Performance View

/// Performance mode - pads trigger pattern playback
struct PatternPerformanceView: View {
    @ObservedObject private var patternManager = PatternManager.shared
    @State private var selectedBankIndex: Int = 0
    @State private var activePatternIds: Set<UUID> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // Bank tabs
            bankTabBar

            Divider()

            // Performance pad grid
            ScrollView {
                performanceGrid
                    .padding()
            }

            // Active patterns indicator
            activePatternBar
        }
    }

    private var bankTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<PatternBank.bankCount, id: \.self) { index in
                Button {
                    selectedBankIndex = index
                } label: {
                    Text("Bank \(patternManager.banks[index].letter)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedBankIndex == index ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedBankIndex == index ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.secondary.opacity(0.1))
    }

    private var performanceGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<PatternBank.patternsPerBank, id: \.self) { slot in
                PerformancePadButton(
                    pattern: patternManager.loadPattern(bank: selectedBankIndex, slot: slot),
                    slotLabel: patternManager.slotIdentifier(bank: selectedBankIndex, slot: slot),
                    isActive: isPatternActive(bank: selectedBankIndex, slot: slot),
                    onTrigger: {
                        triggerPattern(bank: selectedBankIndex, slot: slot)
                    }
                )
            }
        }
    }

    private var activePatternBar: some View {
        HStack {
            Text("Active: ")
                .font(.caption)
                .foregroundColor(.secondary)

            if activePatternIds.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(activePatternIds), id: \.self) { id in
                    if let location = findPatternLocation(id: id),
                       let pattern = patternManager.loadPattern(bank: location.bank, slot: location.slot) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(pattern.color)
                                .frame(width: 8, height: 8)
                            Text(pattern.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }

    private func isPatternActive(bank: Int, slot: Int) -> Bool {
        guard let pattern = patternManager.loadPattern(bank: bank, slot: slot) else { return false }
        return activePatternIds.contains(pattern.id)
    }

    @MainActor
    private func triggerPattern(bank: Int, slot: Int) {
        guard let pattern = patternManager.loadPattern(bank: bank, slot: slot) else { return }

        switch pattern.triggerMode {
        case .oneShot:
            // Play once and remove from active
            SequencerEngine.shared.play(pattern: pattern)
            activePatternIds.insert(pattern.id)
            // Note: Would need to observe pattern completion to remove

        case .toggle:
            if activePatternIds.contains(pattern.id) {
                activePatternIds.remove(pattern.id)
                // If this was the only active pattern, stop
                if activePatternIds.isEmpty {
                    SequencerEngine.shared.stop()
                }
            } else {
                activePatternIds.insert(pattern.id)
                SequencerEngine.shared.play(pattern: pattern)
            }

        case .momentary:
            // Handled by onPressBegan/onPressEnded (not implemented yet)
            activePatternIds.insert(pattern.id)
            SequencerEngine.shared.play(pattern: pattern)
        }
    }

    private func findPatternLocation(id: UUID) -> (bank: Int, slot: Int)? {
        for (bankIndex, bank) in patternManager.banks.enumerated() {
            for (slot, pattern) in bank.patterns.enumerated() {
                if pattern?.id == id {
                    return (bankIndex, slot)
                }
            }
        }
        return nil
    }
}

// MARK: - Performance Pad Button

struct PerformancePadButton: View {
    let pattern: Pattern?
    let slotLabel: String
    let isActive: Bool
    let onTrigger: () -> Void

    var body: some View {
        Button(action: onTrigger) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(pattern?.color ?? Color.secondary.opacity(0.2))
                    .frame(height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Group {
                            if pattern == nil {
                                Image(systemName: "plus")
                                    .foregroundColor(.secondary)
                            } else if isActive {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .shadow(color: isActive ? pattern?.color.opacity(0.5) ?? .clear : .clear, radius: 8)

                Text(pattern?.name ?? "Empty")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(pattern != nil ? .primary : .secondary)

                Text(slotLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(pattern == nil)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Previews

struct PatternBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        PatternBrowserView { _, _ in }
    }
}

struct PatternPerformanceView_Previews: PreviewProvider {
    static var previews: some View {
        PatternPerformanceView()
    }
}
