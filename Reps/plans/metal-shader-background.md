# Metal Shader Background Implementation Plan

## Overview

Implement a working Metal shader background that displays across the entire app behind all content. The previous attempt failed due to the Metal shader file not being added to the Xcode project, causing blank backgrounds.

## Problem Statement

The app has a `MetalGradientView` component that wraps MTKView in UIViewRepresentable, but it displays a blank/black background instead of the animated gradient because:

1. **Critical Issue**: `animated-gradient.metal` file exists at `Reps/Shaders/animated-gradient.metal` but is NOT added to the Xcode project build
2. `device.makeDefaultLibrary()` returns nil when no `.metal` files are compiled
3. Pipeline state creation fails silently, leaving `pipelineState = nil`
4. The `draw(in:)` method guard fails and returns early, showing nothing

Secondary issues that need addressing:
- Views use opaque `RepsTheme.Colors.background` that obscure the Metal view
- ScrollViews have their own backgrounds that need to be transparent
- Cards use `RepsTheme.Colors.surface` (opaque dark gray)

## Technical Approach

### Phase 1: Fix Metal Shader Compilation

**File: `Reps.xcodeproj/project.pbxproj`**

Add `animated-gradient.metal` to:
1. PBXFileReference section
2. PBXBuildFile section
3. PBXSourcesBuildPhase (Sources build phase)

This ensures `device.makeDefaultLibrary()` finds the compiled shader.

### Phase 2: Improve MetalGradientView Robustness

**File: `Reps/Views/Components/MetalGradientView.swift`**

```swift
// Add error handling for library creation
private func setupRenderPipeline() {
    guard let library = device.makeDefaultLibrary() else {
        print("Metal: Failed to create library - ensure .metal files are in build")
        return
    }

    guard let vertexFn = library.makeFunction(name: "gradient_animation_vertex"),
          let fragmentFn = library.makeFunction(name: "gradient_animation_fragment") else {
        print("Metal: Shader functions not found")
        return
    }

    // ... rest of pipeline setup
}

// Add dismantleUIView for proper cleanup
static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
    uiView.isPaused = true
    uiView.delegate = nil
    coordinator.cleanup()
}
```

Add Low Power Mode detection to throttle to 30fps for battery:

```swift
// In Coordinator init
observers.append(NotificationCenter.default.addObserver(
    forName: .NSProcessInfoPowerStateDidChange,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.mtkView?.preferredFramesPerSecond =
        ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
})
```

### Phase 3: Make App Background Transparent

**Philosophy**: The Metal gradient should be the ONLY background. All views should be transparent to reveal it.

#### 3.1 Update RepsTheme Colors

**File: `Reps/Theme/RepsTheme.swift`**

```swift
enum Colors {
    // Change background to clear
    static var background: Color {
        Color.clear  // Was: PaletteManager.shared.activePalette.background
    }

    // Add new opaque background for specific use cases
    static var backgroundSolid: Color {
        PaletteManager.shared.activePalette.background
    }

    // Update surface to semi-transparent for glass effect
    static var surface: Color {
        Color(hex: "1C1C1E").opacity(0.85)  // Was fully opaque
    }
}
```

#### 3.2 Update Views to Use Clear Backgrounds

**Files to modify:**

| File | Change |
|------|--------|
| `ContentView.swift:151` | `.scrollContentBackground(.hidden)` already present |
| `ProfileView.swift:38` | `.scrollContentBackground(.hidden)` already present |
| `SettingsView.swift:186-187` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `PersonalRecordsView.swift:22` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `WorkoutDetailView.swift:23` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `ProgramDetailView.swift:30` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `VolumeBreakdownView.swift:27` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `ContributionGraphView.swift:274` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `ThemeSettingsView.swift:22` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |
| `HistoryView.swift:514` | Change `.background(RepsTheme.Colors.background)` to `.background(Color.clear)` |

#### 3.3 Update NavigationStack Appearance

Ensure navigation bars are transparent:

```swift
// In ContentView or RepsApp
.toolbarBackground(.hidden, for: .navigationBar)
```

### Phase 4: Card Glass Effect (Optional Enhancement)

Make cards have a frosted glass effect to complement the animated background:

**File: `Reps/Theme/RepsTheme.swift` - RepsCardStyle**

```swift
struct RepsCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .fill(.ultraThinMaterial)  // Glass effect
                    .background(
                        RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                            .fill(RepsTheme.Colors.surface.opacity(0.6))
                    )
            )
            // ... rest unchanged
    }
}
```

## Implementation Steps

### Step 1: Add Metal Shader to Xcode Project
1. Open `Reps.xcodeproj` in Xcode
2. Right-click on `Reps` group > Add Files to "Reps"
3. Navigate to `Reps/Shaders/animated-gradient.metal`
4. Ensure "Copy items if needed" is unchecked
5. Ensure target "Reps" is checked
6. Click Add

OR edit `project.pbxproj` directly to add file references.

### Step 2: Add Error Logging
Update `MetalGradientView.swift` with better error handling (see Phase 2).

### Step 3: Clear Backgrounds
Update each view file listed in Phase 3.2.

### Step 4: Build & Test
Run app and verify:
- Metal gradient animates behind all content
- Cards/surfaces are semi-transparent
- No opaque backgrounds obscuring the gradient
- Performance is smooth (60fps, 30fps in Low Power Mode)

### Step 5: Battery Optimization
Add Low Power Mode detection per Phase 2.

## Acceptance Criteria

- [ ] Metal gradient renders animated colors (not blank/black)
- [ ] Gradient visible behind ALL tabs (Home, Programs, Exercises, History, Profile)
- [ ] Cards have slight transparency to show gradient bleeding through
- [ ] NavigationStack/ScrollView backgrounds are transparent
- [ ] 60fps on normal mode, 30fps on Low Power Mode
- [ ] Pauses when app enters background
- [ ] Respects accessibility Reduce Motion setting
- [ ] No memory leaks (proper cleanup in dismantleUIView)

## Files to Modify

### Must Change
1. `Reps.xcodeproj/project.pbxproj` - Add metal shader file
2. `Reps/Views/Components/MetalGradientView.swift` - Error handling + cleanup
3. `Reps/Theme/RepsTheme.swift` - Clear backgrounds + surface opacity

### Background Updates (8 files)
4. `Reps/Views/Profile/SettingsView.swift`
5. `Reps/Views/History/PersonalRecordsView.swift`
6. `Reps/Views/History/WorkoutDetailView.swift`
7. `Reps/Views/Programs/ProgramDetailView.swift`
8. `Reps/Views/Profile/VolumeBreakdownView.swift`
9. `Reps/Views/Profile/ContributionGraphView.swift`
10. `Reps/Views/Profile/ThemeSettingsView.swift`
11. `Reps/ContentView.swift` (HistoryView section)

## Unresolved Questions

1. **Glass effect intensity**: Should surface opacity be 0.6, 0.7, or 0.85?
2. **Full-screen modals**: Should `ActiveWorkoutView` (fullScreenCover) also show gradient, or have solid background?
3. **Sheets**: Should bottom sheets (.sheet) show gradient behind them or use solid backgrounds?
4. **Tab bar**: Should CustomTabBar be semi-transparent to show gradient, or remain opaque for better touch targets?

## ERD

Not applicable - no model changes.

## References

### Internal
- `Reps/Views/Components/MetalGradientView.swift:1-256` - Current Metal view implementation
- `Reps/Shaders/animated-gradient.metal:1-167` - Shader code (not in build)
- `Reps/ContentView.swift:10-14` - Where MetalGradientView is used
- `Reps/Theme/RepsTheme.swift:256-276` - RepsCardStyle modifier

### External
- [Apple MTKView Documentation](https://developer.apple.com/documentation/metalkit/mtkview)
- [Apple Metal Best Practices - Frame Rate](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/FrameRate.html)
- [SwiftUI UIViewRepresentable Memory Management](https://developer.apple.com/documentation/swiftui/uiviewrepresentable/dismantleuiview(_:coordinator:)-94s0o)
