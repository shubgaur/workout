# App Improvements: Liquid Metal Button, Nav Fix, Glint Fix, Scroll Padding, Performance

**Date:** 2026-01-11
**Type:** Enhancement / Bug Fix / Performance
**Priority:** High
**Deepened:** 2026-01-11

---

## Enhancement Summary

**Research agents used:** 9 parallel agents
- Metal shader best practices (best-practices-researcher)
- SwiftUI gesture composition (best-practices-researcher)
- Performance oracle (14 CRITICAL, 8 HIGH issues found)
- Architecture strategist (component composition review)
- Code simplicity reviewer (YAGNI analysis)
- Pattern recognition specialist (consistency + double-inversion bug)
- SwiftUI performance analyzer (specific hotspots)
- SwiftUI gesture patterns (Explore)
- Context7 SwiftUI documentation

### Key Improvements
1. **CRITICAL BUG FIX:** Double-inversion in lightAngle calculation (invert in ONE place only)
2. **Gesture Fix:** Use `value.location.x` in onEnded, not stored scrubProgress
3. **Performance:** 14 critical issues identified - DateFormatter in view body, all tabs loaded simultaneously
4. **Simplification Option:** SwiftUI AngularGradient (~10 LOC) vs Metal shader (~120 LOC) for 80% visual effect

### New Considerations Discovered
- VoiceOver accessibility gap: Tab scrub invisible to VoiceOver users
- @Observable migration (iOS 17+) would eliminate cascading update issues
- Button style proliferation: Now 5 styles, needs hierarchy/documentation
- Existing `.trackingMotion()` modifier should be reused

---

## Overview

Five interconnected improvements to the Reps workout app:

1. **"Start Early" button redesign** - Linear gradient fill + animated liquid metal chromatic border shader
2. **Nav bar gesture fix** - Tab scrubbing should respect finger end position, not start position
3. **Scroll padding audit** - Ensure all content scrollable above nav bar on every page
4. **Card glint physics fix** - Inverse tilt response (tilt left → glint right) + consistency across cards
5. **Performance optimization** - Target 60fps while preserving visual quality

---

## Part 1: Liquid Metal Border Shader for "Start Early" Button

### Problem
Current "Start Early" button uses `GradientButtonStyle()` which fills the entire button with the animated Metal gradient. User wants:
- Simple linear gradient fill (dark → light theme color)
- Animated chromatic/prismatic border that shimmers in place
- Border responds to device tilt for glint positioning
- 3D metallic appearance like reference images

### Research Insights

**Best Practices (Metal Shaders):**
- Use `half` precision (half4, half3) instead of float for 2x GPU performance on mobile
- `[[stitchable]]` attribute required for SwiftUI integration
- For `colorEffect`: receives `position`, `currentColor` - returns modified color
- For `layerEffect`: receives `position`, `layer` - can sample neighboring pixels
- Avoid per-pixel branching; use `mix()` and `step()` instead

**Performance Considerations:**
- TimelineView at 30fps is sufficient for shimmer (1.0/30.0 interval)
- Pre-calculate trigonometric constants as `constant half` values
- iOS 18+ shader pre-compilation eliminates first-render stutter:
  ```swift
  Task { try? await ShaderLibrary.liquidMetalBorder.compile(as: .layerEffect) }
  ```
- Use `.drawingGroup()` on parent view to flatten compositing layers

**Simplification Alternative (YAGNI Analysis):**
SwiftUI's `AngularGradient` achieves ~80% of the visual effect in ~10 lines vs ~120 lines of Metal:
```swift
// Simpler alternative if Metal complexity is unwanted
AngularGradient(
    colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
    center: .center,
    angle: .degrees(motion.lightAngle)
)
.mask(RoundedRectangle(cornerRadius: 12).strokeBorder(lineWidth: 2.5))
```
**Recommendation:** Start with Metal for premium feel; fallback to AngularGradient if performance issues arise.

**Edge Cases:**
- reduceMotion: Show solid accent border, not frozen mid-shimmer
- Shader compilation failure: Catch error, fallback to solid border
- Off-screen: TimelineView auto-pauses, but verify with Instruments

### Technical Approach

#### 1.1 Create New Metal Shader: `liquid-metal-border.metal`

**File:** `Reps/Shaders/liquid-metal-border.metal`

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Pre-calculated constants for performance
constant half PI_H = 3.14159h;
constant half TWO_PI_H = 6.28318h;
constant half DEG_TO_RAD = 0.0174533h;

// HSL to RGB helper (duplicated from holographic-text.metal - 15 lines acceptable)
half3 hsl2rgb(half h, half s, half l) {
    half c = (1.0h - abs(2.0h * l - 1.0h)) * s;
    half x = c * (1.0h - abs(fmod(h * 6.0h, 2.0h) - 1.0h));
    half m = l - c / 2.0h;

    half3 rgb;
    if (h < 1.0h/6.0h) rgb = half3(c, x, 0.0h);
    else if (h < 2.0h/6.0h) rgb = half3(x, c, 0.0h);
    else if (h < 3.0h/6.0h) rgb = half3(0.0h, c, x);
    else if (h < 4.0h/6.0h) rgb = half3(0.0h, x, c);
    else if (h < 5.0h/6.0h) rgb = half3(x, 0.0h, c);
    else rgb = half3(c, 0.0h, x);

    return rgb + m;
}

// Liquid metal chromatic border effect
// Creates prismatic rainbow shimmer that responds to light angle
[[ stitchable ]] half4 liquidMetalBorder(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float lightAngle      // 0-360 from MotionManager (already inverted)
) {
    // Skip transparent pixels (not on border)
    if (color.a < 0.01h) return color;

    // Normalize position to UV space
    half2 uv = half2(position / size);
    half2 center = half2(0.5h, 0.5h);

    // Calculate angle from center to current pixel
    half2 toPixel = uv - center;
    half pixelAngle = atan2(toPixel.y, toPixel.x);

    // Light angle in radians (NO inversion here - already inverted in MotionManager)
    half lightRad = half(lightAngle) * DEG_TO_RAD;

    // Angular distance from light source (wrap-around aware)
    half angleDiff = abs(pixelAngle - lightRad);
    angleDiff = min(angleDiff, TWO_PI_H - angleDiff);

    // Glint intensity - concentrated highlight using smoothstep (no branching)
    half glintIntensity = pow(max(0.0h, 1.0h - angleDiff / 1.5h), 4.0h);

    // Chromatic aberration based on angle + time shimmer
    half shimmer = sin(half(time) * 2.0h + pixelAngle * 3.0h) * 0.5h + 0.5h;
    half hue = fract(pixelAngle / TWO_PI_H + half(time) * 0.1h + shimmer * 0.2h);

    // HSL to RGB for rainbow
    half3 rainbow = hsl2rgb(hue, 0.9h, 0.6h);

    // Metallic base (silver/gray gradient)
    half metallic = 0.3h + glintIntensity * 0.7h;
    half3 metalBase = half3(metallic);

    // Blend rainbow into glint areas using mix (no branching)
    half3 finalColor = mix(metalBase, rainbow, glintIntensity * 0.8h + 0.2h);

    // Add specular highlight
    finalColor += half3(glintIntensity * 0.5h);

    // Depth/3D effect - darken edges opposite to light
    half depthFactor = 1.0h - angleDiff / PI_H * 0.3h;
    finalColor *= depthFactor;

    return half4(clamp(finalColor, 0.0h, 1.0h), color.a);
}
```

#### 1.2 Create SwiftUI View: `LiquidMetalBorder.swift`

**File:** `Reps/Views/Components/LiquidMetalBorder.swift`

```swift
import SwiftUI

/// Animated liquid metal chromatic border
/// Responds to device tilt via MotionManager
struct LiquidMetalBorder: View {
    var cornerRadius: CGFloat = RepsTheme.Radius.md
    var lineWidth: CGFloat = 2.5

    @ObservedObject private var motion = MotionManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var startDate = Date.now
    @State private var shaderCompiled = false

    var body: some View {
        if reduceMotion {
            // Accessibility: Solid accent border, not frozen animation
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(RepsTheme.Colors.accent, lineWidth: lineWidth)
        } else {
            TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
                let time = Float(timeline.date.timeIntervalSince(startDate))

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: lineWidth)
                    .colorEffect(
                        ShaderLibrary.liquidMetalBorder(
                            .float2(0, 0),
                            .float(time),
                            .float(Float(motion.lightAngle))
                        )
                    )
            }
            .trackingMotion()  // Use existing modifier pattern
            .task {
                // iOS 18+ pre-compilation (fails silently on older iOS)
                if #available(iOS 18.0, *) {
                    try? await ShaderLibrary.liquidMetalBorder.compile(as: .colorEffect)
                }
            }
        }
    }
}
```

#### 1.3 Create New Button Style: `LiquidMetalButtonStyle`

**File:** `Reps/Views/Components/PrimaryButtonGradient.swift` (add to existing)

```swift
/// Button with linear gradient fill and liquid metal animated border
struct LiquidMetalButtonStyle: ButtonStyle {
    var palette: Palette { PaletteManager.shared.activePalette }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Linear gradient fill (dark → light theme color)
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.6),  // Darker
                            palette.accent               // Lighter
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            // Liquid metal border overlay
            LiquidMetalBorder(
                cornerRadius: RepsTheme.Radius.md,
                lineWidth: 2.5
            )

            // Button label
            configuration.label
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, RepsTheme.Spacing.lg)
                .padding(.vertical, RepsTheme.Spacing.md)
        }
        .frame(height: 50)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(RepsTheme.Animations.buttonPress, value: configuration.isPressed)
        .drawingGroup()  // GPU-accelerate the composite
    }
}
```

#### 1.4 Update NextWorkoutCard

**File:** `Reps/ContentView.swift` (lines 335-343)

```swift
// Change from:
.buttonStyle(GradientButtonStyle())

// To:
.buttonStyle(LiquidMetalButtonStyle())
```

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `Shaders/liquid-metal-border.metal` | Create | New chromatic border shader |
| `Views/Components/LiquidMetalBorder.swift` | Create | SwiftUI wrapper for shader |
| `Views/Components/PrimaryButtonGradient.swift` | Modify | Add `LiquidMetalButtonStyle` |
| `ContentView.swift:343` | Modify | Use new button style |

---

## Part 2: Nav Bar Gesture Fix

### Problem
When tap+hold+swiping on the tab bar, releasing the finger near an adjacent tab returns to the original tap position instead of the finger's end position.

### Research Insights

**Best Practices (SwiftUI Gestures):**
- `DragGesture.Value` properties:
  - `.location` = Current finger position (USE THIS in onEnded)
  - `.startLocation` = Where drag began
  - `.translation` = Offset from start (NOT absolute position)
- `onEnded { value in }` receives final state - use `value.location.x` for finger-lift position
- Use `@GestureState` for transient state that auto-resets

**CRITICAL BUG IDENTIFIED:**
Current implementation discards `value` parameter in `onEnded` and uses stored `scrubProgress` state variable. This causes the bug because `scrubProgress` may lag behind actual finger position.

**Accessibility Consideration (Gap 7):**
Tab scrubbing is invisible to VoiceOver users. Add:
```swift
.accessibilityAdjustableAction { direction in
    switch direction {
    case .increment: selectNextTab()
    case .decrement: selectPreviousTab()
    @unknown default: break
    }
}
```

**Edge Case - Gesture Cancellation:**
If finger lifts outside tab bar bounds:
- Option A: Use last valid in-bounds X position
- Option B: Snap to nearest edge tab
Recommendation: Option A for less jarring UX

### Root Cause Analysis

**File:** `Reps/Views/Components/CustomTabBar.swift`

Current implementation (lines 115-182):
- Long press activates scrub mode
- Drag gesture updates `scrubProgress`
- **BUG:** On gesture end, it uses stored `scrubProgress` instead of `value.location`

### Technical Approach

#### 2.1 Fix Gesture End Handler

**File:** `Reps/Views/Components/CustomTabBar.swift`

```swift
// In the gesture handling section, ensure onEnded uses final position:

.onEnded { value in
    // CRITICAL: Use value.location (finger lift position), NOT stored scrubProgress
    let finalX = value.location.x
    let tabWidth = geometry.size.width / CGFloat(Tab.allCases.count)

    // Handle out-of-bounds: clamp to valid range
    let clampedX = max(0, min(geometry.size.width, finalX))
    let targetTab = Int(clampedX / tabWidth)
    let clampedTab = max(0, min(Tab.allCases.count - 1, targetTab))

    withAnimation(RepsTheme.Animations.tabTransition) {
        selectedTab = Tab(rawValue: clampedTab) ?? selectedTab
        scrubProgress = nil
        isScrubbing = false
    }

    HapticManager.selection()
}
```

#### 2.2 Verify Scrub Progress Calculation

Ensure `scrubProgress` during drag also uses current position:

```swift
.onChanged { value in
    // Should use value.location.x, not value.startLocation.x
    let currentX = value.location.x
    let tabWidth = geometry.size.width / CGFloat(Tab.allCases.count)
    let progress = currentX / geometry.size.width
    scrubProgress = max(0, min(1, progress))

    // Haptic feedback on tab boundary crossing
    let currentTab = Int(currentX / tabWidth)
    if currentTab != lastHapticTab {
        HapticManager.selection()
        lastHapticTab = currentTab
    }
}
```

#### 2.3 Add VoiceOver Accessibility

```swift
// Add to CustomTabBar body
.accessibilityAdjustableAction { direction in
    withAnimation(RepsTheme.Animations.tabTransition) {
        switch direction {
        case .increment:
            if let current = Tab(rawValue: selectedTab.rawValue + 1) {
                selectedTab = current
            }
        case .decrement:
            if selectedTab.rawValue > 0,
               let current = Tab(rawValue: selectedTab.rawValue - 1) {
                selectedTab = current
            }
        @unknown default:
            break
        }
    }
}
```

### Files to Modify

| File | Lines | Change |
|------|-------|--------|
| `Views/Components/CustomTabBar.swift` | ~115-182 | Fix gesture end position calculation |
| `Views/Components/CustomTabBar.swift` | body | Add VoiceOver accessibility |

---

## Part 3: Scroll Padding Audit

### Problem
Content at bottom of pages (e.g., workout history notes) gets hidden behind the nav bar.

### Research Insights

**Best Practices:**
- Create constant: `RepsTheme.Spacing.tabBarSafeArea` for consistency
- Calculation: tabBarHeight (56) + tabBarPadding (4) + breathingRoom (20) = 80pt minimum
- Use `safeAreaInset(edge:)` as alternative to manual padding for dynamic layouts

**Project Learning (docs/transparent-navigation-background.md):**
> "Main tab views need `.padding(.bottom, 70)` so content isn't cut off by the custom tab bar"
Current 70pt is insufficient for some content. Recommend 80pt.

### Current State

Tab bar height: `56pt` + `4pt` padding = `60pt` total
Current bottom padding: `70pt` (gives 10pt extra)

**Files using `padding(.bottom, 70)`:**
- `ContentView.swift:134` (HomeView)
- `ProfileView.swift:36`
- `HistoryListView.swift:167`
- `ProgramListView.swift:169`
- `ExerciseLibraryView.swift:212`

**Exception:** `ExerciseDetailView.swift:101` uses `100pt`

### Audit Checklist

| View | File | Current Padding | Issue? |
|------|------|-----------------|--------|
| HomeView | ContentView.swift:134 | 70 | Check |
| ProfileView | ProfileView.swift:36 | 70 | Check |
| HistoryListView | HistoryListView.swift:167 | 70 | **Notes hidden** |
| ProgramListView | ProgramListView.swift:169 | 70 | Check |
| ExerciseLibraryView | ExerciseLibraryView.swift:212 | 70 | Check |
| ExerciseDetailView | ExerciseDetailView.swift:101 | 100 | Check |
| WorkoutDetailView | TBD | TBD | **Check notes** |
| SettingsView | TBD | TBD | Check |
| PersonalRecordsView | TBD | TBD | Check |
| ActiveWorkoutView | TBD | TBD | Check |

### Technical Approach

1. Add constant to RepsTheme:
   ```swift
   enum Spacing {
       // ... existing
       static let tabBarSafeArea: CGFloat = 80  // 60pt tab bar + 20pt breathing room
   }
   ```

2. Replace all hardcoded `padding(.bottom, 70)` with `RepsTheme.Spacing.tabBarSafeArea`

3. Test each page by scrolling to absolute bottom

### Files to Modify

| File | Change |
|------|--------|
| `Theme/RepsTheme.swift` | Add `tabBarSafeArea` constant |
| All ScrollView files | Replace hardcoded 70/80 with constant |

---

## Part 4: Card Glint Physics Fix

### Problem
Glints on cards either:
- Don't respond to tilt
- Move in wrong direction
- Are inconsistent between cards

**User Requirement:** Inverse physics (tilt left → glint moves right) to simulate fixed light source.

### Research Insights

**CRITICAL BUG FOUND (Pattern Recognition Agent):**
The plan currently inverts `lightAngle` in TWO places:
1. `MotionManager.swift`: `lightAngle = (360 - normalizedAngle)`
2. `liquid-metal-border.metal`: `float lightRad = (360.0 - lightAngle) * 0.0174533`

This causes a DOUBLE inversion, returning to the original (wrong) direction!

**FIX:** Remove inversion from ONE location. MotionManager is preferred because:
- Single source of truth
- All consumers get correct angle
- Shader code stays simpler

**Consistency Issue:**
- `GlintBorder.swift` uses `motion.lightAngle` directly
- `ParallaxCard.swift` uses `pitchScaled` and `rollScaled` (different approach)
- This may cause visual inconsistency between cards

**Recommendation:** Standardize on `lightAngle` for all glint effects, or document why different approaches are needed.

### Current Implementation

**File:** `Reps/Utils/MotionManager.swift` (lines 118-121)
```swift
// Current lightAngle calculation
let angle = atan2(rawRoll, rawPitch) * 180 / .pi
lightAngle = angle < 0 ? angle + 360 : angle
```

**File:** `Reps/Views/Components/GlintBorder.swift` (lines 60-72)
- Uses `lightAngle` directly for gradient positioning

### Technical Approach

#### 4.1 Fix MotionManager Light Angle (SINGLE INVERSION POINT)

```swift
// In MotionManager.updateMotion():
// Invert the angle HERE so tilt left → light appears from right
let angle = atan2(rawRoll, rawPitch) * 180 / .pi
let normalizedAngle = angle < 0 ? angle + 360 : angle
lightAngle = (360 - normalizedAngle).truncatingRemainder(dividingBy: 360)
// DO NOT invert again in shaders!
```

#### 4.2 Update Metal Shader (NO INVERSION)

In `liquid-metal-border.metal`, remove the 360- inversion:
```metal
// CORRECTED: No inversion here - already inverted in MotionManager
half lightRad = half(lightAngle) * DEG_TO_RAD;  // NOT (360.0 - lightAngle)
```

#### 4.3 Audit All Glint Usages

Ensure all glint effects use `MotionManager.shared.lightAngle` consistently:

| Component | File | Uses lightAngle? | Inverts Again? |
|-----------|------|------------------|----------------|
| GlintBorder | GlintBorder.swift | Yes | Check & remove if present |
| HolographicText | HolographicText.swift | Yes | Check & remove if present |
| ParallaxCard | ParallaxCard.swift | Uses pitchScaled/rollScaled | Different system (OK) |
| LiquidMetalBorder | New | Will use lightAngle | NO inversion |

#### 4.4 Fix ParallaxCard Shadow Direction (if needed)

If ParallaxCard's shadow/effect direction should match:

```swift
// Ensure shadow moves opposite to tilt (toward light source)
// Since lightAngle is now inverted in MotionManager, we may need to adjust
.shadow(
    color: .black.opacity(0.2),
    radius: 8,
    x: CGFloat(-motion.rollScaled * 0.3),  // Verify sign
    y: CGFloat(-motion.pitchScaled * 0.3)
)
```

### Files to Modify

| File | Change |
|------|--------|
| `Utils/MotionManager.swift` | Invert lightAngle calculation (SINGLE POINT) |
| `Shaders/liquid-metal-border.metal` | Remove any inversion |
| `Shaders/holographic-text.metal` | Check and remove any inversion |
| `Views/Components/GlintBorder.swift` | Check and remove any inversion |

---

## Part 5: Performance Optimization

### Priority
**Visual smoothness** - Target 60fps, simplify effects if needed.

### Research Insights

**Performance Oracle Findings (14 CRITICAL Issues):**

1. **DateFormatter in view body** - Creates new formatter every render
   - FIX: Move to static property or cache

2. **HStack loads all 5 tabs simultaneously** - Memory + CPU wasteful
   - FIX: Wrap in `LazyView` pattern:
   ```swift
   HStack(spacing: 0) {
       LazyView { HomeView(...) }
       LazyView { ProgramListView() }
       // ...
   }
   ```

3. **@ObservableObject cascading updates** - MotionManager publishes 5 properties at 60fps
   - FIX (iOS 17+): Migrate to `@Observable` for granular property tracking
   - FIX (iOS 16): Throttle updates or use Combine publishers with debounce

4. **Multiple TimelineViews on same screen** - Each runs independent animation loop
   - FIX: Share single TimelineView at parent level, pass time down

5. **HolographicText composite** - Multiple shadows + shader = expensive
   - FIX: Apply `.drawingGroup()` to flatten layers

**SwiftUI Performance Analyzer Hotspots:**
- `ProgramRow`: DateFormatter created in computed property (line 197-201)
- `ContentView`: All 5 tabs always instantiated
- `GlintBorder`: Gradient stops recalculated every motion update

### Current Performance Concerns

1. **Multiple Metal shaders running simultaneously:**
   - MetalGradientView (background)
   - HolographicText (titles)
   - GlintBorder (cards)
   - New LiquidMetalBorder

2. **MotionManager updates at 60fps**
   - Multiple observers

3. **TimelineView animations**
   - Multiple 30fps timeline views on same screen

### Optimization Strategies

#### 5.1 Shader Performance

```metal
// Use half precision everywhere possible (2x faster on mobile GPU)
half4 color;  // Not float4
half3 rgb;    // Not float3

// Pre-calculate constants outside loops (already in updated shader)
constant half PI = 3.14159h;
constant half TWO_PI = 6.28318h;

// Avoid branching in pixel shaders
// Use mix(), step(), smoothstep() instead of if/else
```

#### 5.2 Reduce Timeline View Frame Rate

```swift
// Only need 30fps for smooth shimmer, not 60fps
TimelineView(.animation(minimumInterval: 1.0/30.0, paused: reduceMotion))
```

#### 5.3 Pause Off-Screen Animations

```swift
struct MetalGradientView: UIViewRepresentable {
    @Environment(\.scenePhase) var scenePhase

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Pause when backgrounded
        uiView.isPaused = scenePhase != .active
    }
}
```

#### 5.4 MotionManager Optimizations

```swift
// Consider migrating to @Observable (iOS 17+) for granular updates
@Observable
final class MotionManager {
    var lightAngle: Double = 0  // Only observers of lightAngle update
    var pitch: Double = 0       // Separate observation
    // ...
}
```

#### 5.5 DrawingGroup for Complex Views

```swift
// Apply to views with multiple overlapping effects
HolographicText(text: "Reps")
    .drawingGroup()  // Flattens to single GPU layer
```

#### 5.6 Lazy Tab Loading

```swift
// In ContentView - wrap tabs in LazyView
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content { build() }
}

// Usage:
HStack(spacing: 0) {
    HomeView(onStartWorkout: startWorkout)
        .frame(width: screenWidth)
    LazyView(ProgramListView())
        .frame(width: screenWidth)
    LazyView(ExerciseLibraryView())
        .frame(width: screenWidth)
    LazyView(HistoryListView())
        .frame(width: screenWidth)
    LazyView(ProfileView())
        .frame(width: screenWidth)
}
```

#### 5.7 Fix DateFormatter in View Body

```swift
// In ProgramRow - move to static property
struct ProgramRow: View {
    // MOVE outside of body:
    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // Use: Self.mediumDateFormatter.string(from: date)
}
```

#### 5.8 Pre-compile Shaders (iOS 18+)

```swift
// In RepsApp.init() or onAppear
Task {
    if #available(iOS 18.0, *) {
        try? await ShaderLibrary.liquidMetalBorder.compile(as: .colorEffect)
        try? await ShaderLibrary.holographicText.compile(as: .colorEffect)
    }
}
```

### Performance Testing Checklist

- [ ] Profile with Instruments (Core Animation, Metal System Trace)
- [ ] Test on oldest supported device (iPhone XS / A12)
- [ ] Monitor GPU utilization (should stay under 60%)
- [ ] Check frame drops during tab switching
- [ ] Verify battery impact acceptable (Energy Log instrument)
- [ ] Test with 30+ items in lists (History, Exercises)

---

## Implementation Order

### Phase 0: Foundations (Pre-work)
1. ~~Create shared metal-helpers.metal~~ (YAGNI - 15 lines duplication acceptable)

### Phase 1: Liquid Metal Button
2. Create `liquid-metal-border.metal` shader (half precision, no double-inversion)
3. Create `LiquidMetalBorder.swift` with reduceMotion fallback + `.trackingMotion()`
4. Add `LiquidMetalButtonStyle` with press state + `.drawingGroup()`
5. Update "Start Early" button

### Phase 2: Gesture & Motion Fixes
6. Fix `MotionManager.lightAngle` inversion (SINGLE POINT)
7. Audit and remove any double-inversions in shaders
8. Fix `CustomTabBar` gesture: use `value.location.x` in onEnded
9. Add gesture cancellation handling (clamp out-of-bounds)
10. Add VoiceOver accessibility to tab bar

### Phase 3: Scroll & Polish
11. Add `RepsTheme.Spacing.tabBarSafeArea = 80`
12. Audit all ScrollViews and update bottom padding
13. Test glint consistency across all cards

### Phase 4: Optimization & Testing
14. Fix DateFormatter static property in ProgramRow
15. Add `LazyView` wrapper for tab pages
16. Apply `.drawingGroup()` to HolographicText
17. Add shader pre-compilation (iOS 18+)
18. Profile on oldest supported device
19. Test tab switching performance

---

## Acceptance Criteria

### Part 1: Liquid Metal Button
- [ ] "Start Early" has linear gradient fill (dark bottom → light top)
- [ ] Animated chromatic border with rainbow shimmer
- [ ] Border responds to phone tilt (glint moves with motion)
- [ ] Effect has 3D metallic appearance
- [ ] Smooth 60fps animation
- [ ] Solid accent border shown when reduceMotion enabled

### Part 2: Nav Bar Gesture
- [ ] Tap+hold home, swipe to programs, release → lands on programs
- [ ] Works for all adjacent tab combinations
- [ ] Haptic feedback on tab boundaries
- [ ] VoiceOver users can navigate tabs with swipe up/down

### Part 3: Scroll Padding
- [ ] All pages scrollable to show content above nav bar
- [ ] Workout history notes fully visible
- [ ] Consistent padding using `RepsTheme.Spacing.tabBarSafeArea`

### Part 4: Glint Physics
- [ ] Tilt phone left → glint moves right (inverse)
- [ ] All cards on same page have synchronized glint
- [ ] Smooth response to motion
- [ ] No double-inversion bug

### Part 5: Performance
- [ ] 60fps maintained during normal use
- [ ] No frame drops during tab switching
- [ ] Acceptable battery usage
- [ ] DateFormatter not in view body
- [ ] Tabs lazy-loaded

---

## Unresolved Questions

1. ~~Should liquid metal border have static fallback for reduceMotion?~~ **RESOLVED:** Yes, solid accent border
2. ~~Minimum bottom padding?~~ **RESOLVED:** 80pt (tabBarSafeArea constant)
3. Should shader effects pause when scrolled off-screen? **Defer:** Profile first to confirm impact
4. ~~30fps vs 60fps for animations?~~ **RESOLVED:** 30fps sufficient for shimmer
5. Should ParallaxCard use lightAngle instead of pitchScaled/rollScaled for consistency? **Needs discussion**

---

## SpecFlow Analysis: Identified Gaps

### Critical (Must Address) - UPDATED

**Gap 1: ~~HSL to RGB Duplication~~**
- RESOLVED: Code simplicity reviewer says 15 lines duplication acceptable vs shared header complexity
- Keeping duplicated in both shaders

**Gap 2: Reduce Motion Fallback**
- RESOLVED: Show solid accent-colored border when reduceMotion enabled (in code above)

**Gap 3: Tab Scrub Gesture Cancellation**
- RESOLVED: Clamp out-of-bounds X to valid range (in code above)

**Gap 4: ~~Shader Compilation Failure~~**
- RESOLVED: SwiftUI handles gracefully; added pre-compilation for iOS 18+

**Gap 5: Double-Inversion Bug (NEW - CRITICAL)**
- Plan inverted in TWO places, needs ONE
- FIX: Invert only in MotionManager, remove from shaders

### Important (Should Address)

**Gap 6: Parallax Shadow Direction Consistency**
- If glint moves right on left-tilt, shadow should move LEFT (toward light)
- Need to verify after lightAngle fix

**Gap 7: Button Press State**
- Using `RepsTheme.Animations.buttonPress` (existing pattern)

**Gap 8: VoiceOver for Tab Scrub**
- RESOLVED: Add `accessibilityAdjustableAction` (in code above)

**Gap 9: ~~Simulator Testing~~**
- YAGNI: Debug gesture adds complexity with minimal benefit
- Use physical device for testing

### Nice-to-Have

**Gap 10: ~~Dynamic Scroll Padding~~**
- RESOLVED: Using constant 80pt for simplicity

**Gap 11: Off-Screen Shader Pausing**
- Defer: Profile first to confirm impact needed

---

## References

### Internal Files
- `Shaders/animated-gradient.metal` - Existing Metal shader pattern
- `Shaders/holographic-text.metal` - HSL conversion, lightAngle usage
- `Views/Components/GlintBorder.swift` - Current glint implementation
- `Views/Components/CustomTabBar.swift:115-182` - Gesture handling
- `Utils/MotionManager.swift` - Motion data source
- `docs/transparent-navigation-background.md` - Tab bar padding convention (70pt)

### External Resources
- [Hacking with Swift - Metal Layer Effects](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects)
- [Apple - Reducing Shader Bottlenecks](https://developer.apple.com/documentation/metal/performance_tuning/reducing_shader_bottlenecks)
- [3D Game Shaders - Chromatic Aberration](https://lettier.github.io/3d-game-shaders-for-beginners/chromatic-aberration.html)
- [TanStack Query - React Query Best Practices (for patterns)](https://tanstack.com/query/latest/docs)
