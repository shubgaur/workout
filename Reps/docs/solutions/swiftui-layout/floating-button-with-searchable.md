---
title: "Floating Button Alignment with .searchable() Modifier"
category: swiftui-layout
tags: [swiftui, searchable, safe-area, floating-button, physical-device]
symptom: "Floating button positioned higher on physical device than simulator"
root_cause: ".searchable() modifier affects safe area calculations differently on physical devices"
---

# Floating Button Alignment with .searchable()

## Problem

Floating action buttons appear at different vertical positions when:
- View A has `.searchable()` modifier
- View B does not have `.searchable()`
- Both use identical padding values

**Key insight**: This only manifests on **physical devices**, not simulators.

## Root Cause

`.searchable()` creates keyboard-related safe area insets that compound with manual padding. The effect is device-specific due to how iOS calculates safe areas on real hardware.

## Anti-Pattern

```swift
// DON'T: Button inside NavigationStack with searchable
var body: some View {
    NavigationStack {
        ZStack(alignment: .bottomTrailing) {
            content

            FloatingButton()
                .padding(.bottom, 80)  // Affected by searchable's safe area
        }
        .searchable(text: $searchText)
    }
}
```

## Solution

**Isolate the button outside NavigationStack** to escape searchable's safe area influence:

```swift
// DO: Button completely outside NavigationStack
var body: some View {
    ZStack(alignment: .bottomTrailing) {
        NavigationStack {
            content
                .searchable(text: $searchText)
        }

        // Button isolated from searchable's safe area effects
        FloatingButton()
            .padding(.trailing, RepsTheme.Spacing.md)
            .padding(.bottom, 20)  // Reduced from 80pt
    }
}
```

## Padding Adjustment

When moving the button outside NavigationStack:
- Original padding inside: `80pt` (tabBarSafeArea)
- Required padding outside: `20pt`

The ~60pt difference accounts for the safe area that was previously being double-counted.

## Testing Checklist

- [ ] Compare button positions on **physical device** (not just simulator)
- [ ] Test both views side-by-side (with/without searchable)
- [ ] Verify across screen sizes (Pro vs Pro Max)

## Files Reference

- `ExerciseLibraryView.swift` - Has searchable, button outside NavigationStack
- `ProgramListView.swift` - No searchable, standard positioning

## Key Takeaway

When using `.searchable()` with floating buttons:
1. Place button **outside** NavigationStack
2. Reduce bottom padding (searchable adds its own safe area)
3. Always verify on **physical device** - simulator won't show the issue
