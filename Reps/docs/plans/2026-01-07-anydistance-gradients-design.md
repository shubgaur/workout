# AnyDistance-Style Gradients + Dark Settings Implementation Plan

## Overview

Implement AnyDistance-inspired animated gradients with palette-aware color schemes, add medium-accent gradient effects to primary action buttons, and fix Settings page to use dark theme.

---

## Part 1: Multi-Page Gradient System

### Palette → Gradient Page Mapping

| Palette | Page | Color Scheme |
|---------|------|--------------|
| Dark (orange #FF5500) | 0 | Orange/red (warm energy) |
| Sunset (orange #F97316) | 0 | Orange/red (warm energy) |
| Ember (red #EF4444) | 0 | Orange/red (warm energy) |
| Ocean (cyan #0EA5E9) | 1 | Blue/cyan (cool calm) |
| Midnight (indigo #6366F1) | 1 | Blue/cyan (cool calm) |
| Forest (green #30D158) | 2 | Cyan/teal/green (fresh) |
| Custom palettes | Dynamic | Based on accent hue |

### Metal Shader Updates

**File:** `Reps/Shaders/animated-gradient.metal`

Changes:
1. Add `page` uniform to Uniforms struct
2. Add page calculation based on palette accent hue
3. Keep existing 10-blob algorithm with coordinate warping
4. Use exact AnyDistance color sets per page

```metal
struct Uniforms {
    float time;
    int page;  // NEW: 0-3 based on palette
    float3 accentColor;
    float3 backgroundColor;
    float3 secondaryColor;
};
```

### MetalGradientView Updates

**File:** `Reps/Views/Components/MetalGradientView.swift`

Changes:
1. Add `gradientPage` computed property that maps palette to page (0-3)
2. Pass page uniform to shader
3. Add hue-based fallback for custom palettes

```swift
private var gradientPage: Int {
    let palette = palette ?? PaletteManager.shared.activePalette
    switch palette.name {
    case "Dark", "Sunset", "Ember": return 0  // Orange/red
    case "Ocean", "Midnight": return 1        // Blue/cyan
    case "Forest": return 2                   // Teal/green
    default:
        // Hue-based detection for Magic palettes
        let hue = palette.accentColor.hue
        if hue < 0.1 || hue > 0.9 { return 0 }      // Red/orange
        else if hue < 0.55 { return 2 }              // Green/teal
        else { return 1 }                            // Blue
    }
}
```

---

## Part 2: Button Gradient Component

### Design

Create `PrimaryButtonGradient` - SwiftUI component with animated ellipses using palette colors instead of rainbow spectrum.

**Characteristics:**
- 15-20 blurred ellipses (not 50 like AccessCodeField - scaled down for buttons)
- Colors derived from palette accent + secondary
- Animation: subtle position shifts, ~3-4 second loops
- Opacity: 0.4-0.6 (medium accent, visible but not overwhelming)
- Masked to button shape with rounded corners

### New File: `Reps/Views/Components/PrimaryButtonGradient.swift`

```swift
struct PrimaryButtonGradient: View {
    @State private var animate = false
    var palette: Palette = PaletteManager.shared.activePalette

    var body: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { idx in
                let color = blobColor(for: idx)
                Ellipse()
                    .fill(color)
                    .frame(width: blobWidth(idx), height: blobHeight(idx))
                    .blur(radius: 15)
                    .opacity(0.5)
                    .offset(x: xOffset(idx), y: yOffset(idx))
                    .animation(
                        .easeInOut(duration: duration(idx))
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
        .drawingGroup()
        .onAppear { animate = true }
    }

    private func blobColor(for idx: Int) -> Color {
        // Alternate between accent, secondary, and darker variants
        let colors = [
            palette.accent,
            palette.secondary,
            palette.accent.opacity(0.7),
            palette.secondary.opacity(0.8)
        ]
        return colors[idx % colors.count]
    }
}
```

### Integration with RepsButtonStyle

**File:** `Reps/Theme/RepsTheme.swift` (ButtonStyles section)

Update `RepsButtonStyle` for `.primary` style to include gradient background:

```swift
case .primary:
    ZStack {
        PrimaryButtonGradient()
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))

        configuration.label
            .font(RepsTheme.Typography.headline)
            .foregroundStyle(.white)
    }
    .frame(height: 50)
```

### Buttons That Get Gradient

Only primary action buttons:
- "Finish" (ActiveWorkoutView toolbar)
- "Create" (SupersetSelectionBanner)
- "Save" (settings/form submissions)
- "Start Workout" (workout templates)

---

## Part 3: Settings Dark Theme

### Problem

SettingsView uses default `List` which renders with system light/dark mode. App forces dark mode but Settings page appears light because `List` inherits system appearance.

### Solution

1. Add `.preferredColorScheme(.dark)` to SettingsView
2. Apply custom scrollContentBackground and listRowBackground
3. Use RepsTheme colors for all text and backgrounds

### Changes to SettingsView.swift

```swift
var body: some View {
    List {
        // ... existing sections
    }
    .scrollContentBackground(.hidden)
    .background(RepsTheme.Colors.background)
    .listRowBackground(RepsTheme.Colors.surface)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .preferredColorScheme(.dark)
}
```

Apply to each Section:
```swift
Section {
    // content
}
.listRowBackground(RepsTheme.Colors.surface)
```

---

## Part 4: Gradient Integration Points

### Loading States
- Create `LoadingGradientView` wrapper
- Use in: Program loading, workout history loading, exercise library loading
- Full-screen animated gradient with centered spinner

### Active Workout
- Already has AnimatedGradientView background
- Upgrade to MetalGradientView with page support
- Use page 0 (orange/red) by default for energy, or respect palette

### Settings Page
- Subtle gradient header behind "Settings" title (optional)
- Or: solid dark background with gradient accent elements

---

## Files to Create

| File | Purpose |
|------|---------|
| `Views/Components/PrimaryButtonGradient.swift` | Animated button gradient component |
| `Views/Components/LoadingGradientView.swift` | Full-screen loading gradient wrapper |

## Files to Modify

| File | Change |
|------|--------|
| `Shaders/animated-gradient.metal` | Add page uniform, use AnyDistance color sets |
| `Views/Components/MetalGradientView.swift` | Add palette→page mapping logic |
| `Theme/RepsTheme.swift` | Update RepsButtonStyle.primary to use gradient |
| `Views/Profile/SettingsView.swift` | Dark theme styling |
| `Views/Workout/ActiveWorkoutView.swift` | Use MetalGradientView instead of AnimatedGradientView |

---

## Implementation Order

1. **Update Metal shader** with page support + AnyDistance color sets
2. **Update MetalGradientView** with palette→page mapping
3. **Create PrimaryButtonGradient** component
4. **Integrate button gradient** into RepsButtonStyle
5. **Fix SettingsView** dark theme
6. **Upgrade ActiveWorkoutView** to MetalGradientView
7. **Create LoadingGradientView** for loading states
8. **Test** all gradient variations with different palettes

---

## Success Criteria

- [ ] Selecting Ocean palette shows blue/cyan gradient
- [ ] Selecting Sunset/Ember shows orange/red gradient
- [ ] Selecting Forest shows teal/green gradient
- [ ] Primary buttons have subtle animated gradient
- [ ] Settings page is fully dark themed
- [ ] Active workout shows smooth 60fps gradient
- [ ] Loading states use appropriate gradient background
