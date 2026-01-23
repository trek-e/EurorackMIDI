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

// MARK: - Preview

struct PatternBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        PatternBrowserView { pattern, location in
            print("Selected: \(pattern.name) at bank \(location.bank), slot \(location.slot)")
        }
    }
}
