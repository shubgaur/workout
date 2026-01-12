# Fix Glint Synchronization Across Cards

## Problem

The glint border effect moves at different rates for different cards when tilting the device. Quick Start card barely shifts while Recent Workouts card shifts significantly.

## Root Causes

1. **Per-instance spring animations** - Each card has its own `.animation(.spring(...))` modifier that starts independently when the view appears
2. **View appearance timing** - Cards appear at different times, so their spring animations start from different states
3. **Motion value reset** - `MotionManager.stopUpdates()` resets `lightAngle` to 0 when refcount hits 0, causing jarring resets

## iOS 26 Liquid Glass Reference

Apple's Liquid Glass system uses:
- **GlassEffectContainer** - Groups glass elements for unified rendering and lighting
- **Unified light simulation** - All elements respond identically to the same light source
- **System-managed animation** - No per-view animation timing

---

## Solution

### Part 1: Move Animation to MotionManager

Remove per-view animation. Animate the `lightAngle` at the source using `withAnimation`.

**File**: `Utils/MotionManager.swift`

Current (problematic):
```swift
// Raw updates without animation
lightAngle = newAngle
```

New approach:
```swift
// Animate at the source - all subscribers see same animated value
withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
    lightAngle = newAngle
}
```

### Part 2: Remove Per-View Animation

**File**: `Views/Components/GlintBorder.swift`

Remove the `.animation()` modifier from `GlintBorderModifier`:

```swift
// REMOVE this line (~line 40)
.animation(.spring(response: 0.2, dampingFraction: 0.85), value: motion.lightAngle)
```

The animation now happens at the source (MotionManager), so all views receive pre-animated values.

### Part 3: Don't Reset Motion Values

**File**: `Utils/MotionManager.swift`

In `stopUpdates()`, don't reset values to 0:

```swift
func stopUpdates() {
    referenceCount -= 1
    if referenceCount <= 0 {
        referenceCount = 0
        motionManager.stopDeviceMotionUpdates()
        // DON'T reset lightAngle to 0
        // Keep last known value for smooth resume
    }
}
```

### Part 4: Pre-warm MotionManager at App Launch

**File**: `RepsApp.swift`

Start motion updates early so all cards see the same initial state:

```swift
@main
struct RepsApp: App {
    init() {
        // Pre-warm motion manager
        MotionManager.shared.startUpdates()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Files to Modify

| File | Change |
|------|--------|
| `Utils/MotionManager.swift` | Add `withAnimation` around lightAngle updates, don't reset values in stopUpdates |
| `Views/Components/GlintBorder.swift` | Remove `.animation()` modifier |
| `RepsApp.swift` | Pre-warm MotionManager in init |

---

## Verification

1. Build and run on physical device
2. Tilt device left/right
3. All cards should shift glint at exactly the same rate
4. No card should have more or less movement than others
5. Glint should feel responsive (0.2s spring response)

---

## Unresolved Questions

- Should we match iOS 26's exact spring parameters? (Currently using response: 0.2, dampingFraction: 0.85)
- Should MotionManager stay running forever or use smarter lifecycle?
