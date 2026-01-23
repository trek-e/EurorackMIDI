# Future Features

## Keyboard Control for Pads and Piano Keys

**Priority:** Medium
**Complexity:** Moderate

Add support for physical keyboard input to control the on-screen pads and piano keys.

### Requirements

1. **Default Keyboard Mapping for Pads (16-pad grid)**
   - Row 1: `1` `2` `3` `4` → Pads 1-4
   - Row 2: `Q` `W` `E` `R` → Pads 5-8
   - Row 3: `A` `S` `D` `F` → Pads 9-12
   - Row 4: `Z` `X` `C` `V` → Pads 13-16

2. **Default Keyboard Mapping for Piano**
   - Lower octave: `A` `W` `S` `E` `D` `F` `T` `G` `Y` `H` `U` `J` → C to B
   - Upper octave: `K` `O` `L` `P` `;` `'` → C to E (next octave)
   - Octave shift: `-` (down) `=` (up)

3. **Implementation Notes**
   - Use `NSEvent.addLocalMonitorForEvents` on macOS
   - Use SwiftUI keyboard shortcuts or focusable views
   - Configurable mappings stored in DeviceProfile
   - Visual feedback when keyboard triggers a pad/key

---

## Adaptive Grid Size for Larger Screens

**Priority:** Medium
**Complexity:** Moderate

On larger screens (iPads, Macs), expand the control surfaces to use available space.

### Requirements

1. **Pads View**
   - Small screens (iPhone): 4x4 grid (16 pads)
   - Medium screens (iPad portrait): 6x6 grid (36 pads)
   - Large screens (iPad landscape, Mac): 8x8 grid (64 pads)
   - Use `GeometryReader` to detect available size
   - Smooth transitions when rotating device

2. **Piano Keyboard View**
   - Small screens: 2 octaves (current)
   - Medium screens: 3 octaves
   - Large screens: 4-5 octaves
   - Scale key sizes proportionally to fill width
   - Consider min/max key widths for playability

3. **Implementation Notes**
   - Calculate grid size based on `GeometryReader` dimensions
   - Minimum pad size: 44pt (Apple HIG touch target)
   - Maximum pad size: 120pt (usability)
   - Update `padCount` dynamically
   - Store preference for pad count override in DeviceProfile

### Size Breakpoints

```swift
enum ScreenSize {
    case compact    // < 500pt width: 16 pads, 2 octaves
    case regular    // 500-900pt: 36 pads, 3 octaves
    case large      // > 900pt: 64 pads, 4+ octaves
}
```

---

## Implementation Plan

### Phase 1: Adaptive Grid
1. Add `ScreenSizeCategory` environment value reader
2. Compute pad count based on available size
3. Update `PerformancePadsView` to use dynamic grid
4. Update `PianoKeyboardView` to scale octaves

### Phase 2: Keyboard Control
1. Create `KeyboardInputManager` class
2. Add keyboard event monitoring (macOS)
3. Create configurable key mapping model
4. Add settings UI for customizing mappings
5. Add visual feedback for keyboard-triggered inputs

---

## Current Implementation Reference

**PerformancePadsView.swift**
- Uses `LazyVGrid` with adaptive columns (80-150pt)
- Fixed 16 pads (`padCount = 16`)
- Base octave C2 (MIDI note 36)

**PianoKeyboardView.swift**
- Fixed 2 octave span (`octaveSpan = 2`)
- White key width: 40pt
- Black key width: 28pt
- Base octave C3

**PadButtonView.swift**
- Uses `DragGesture` for touch input
- Fixed velocity (100) - should respect profile velocity curve
