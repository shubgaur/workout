# Glint Cleanup & Tab Active Indicator

## Summary

1. **Tab bar**: Replace moving glint with static indicator on active tab only
2. **Cards**: Remove glints entirely
3. **"Start Early" button**: Already has liquid metal border ✓ (no changes needed)

---

## Change 1: Tab Bar - Active Tab Indicator

### Problem
Currently the entire tab bar has a motion-responsive glint that moves with device tilt. User wants only the active tab to have a glint indicator (static, not moving).

### Solution
Remove the tab bar's `.glintBorder()` and add a subtle capsule background with a static accent glow behind the active tab.

### File: `Reps/Views/Components/CustomTabBar.swift`

**Remove line 63:**
```swift
// DELETE THIS LINE:
.glintBorder(cornerRadius: RepsTheme.Radius.lg)
```

**Modify `tabButton` function (lines 68-118):**

Add a background capsule with glint to the active tab:

```swift
@ViewBuilder
private func tabButton(for tab: Tab, index: Int, tabBarWidth: CGFloat) -> some View {
    let isSelected = selectedTab == tab

    Button {
        guard !isScrubbing else { return }
        HapticManager.tabChanged()
        withAnimation(RepsTheme.Animations.tabTransition) {
            selectedTab = tab
        }
    } label: {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 22))
                .symbolVariant(isSelected ? .fill : .none)
                .scaleEffect(magnificationScale(for: index, tabBarWidth: tabBarWidth))
                .offset(y: magnificationYOffset(for: index, tabBarWidth: tabBarWidth))
                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scrubLocation)

            Text(tab.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(tabColor(for: tab, index: index))
        .frame(maxWidth: .infinity)
        .padding(.vertical, RepsTheme.Spacing.xs)
        .background(
            // Static glint indicator for active tab
            Group {
                if isSelected {
                    Capsule()
                        .fill(RepsTheme.Colors.accent.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            RepsTheme.Colors.accent.opacity(0.6),
                                            RepsTheme.Colors.accent.opacity(0.2),
                                            .clear,
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
        )
    }
    .buttonStyle(.plain)
    // ... accessibility code unchanged
}
```

---

## Change 2: Remove Glints from Cards

### File: `Reps/Theme/RepsTheme.swift`

**Line 196 - Remove `.glintBorder()` from `RepsCardStyle`:**

```swift
// BEFORE (line 196):
.glintBorder(cornerRadius: RepsTheme.Radius.md)

// AFTER: DELETE THIS LINE ENTIRELY
```

The `RepsCardStyle` should become:

```swift
struct RepsCardStyle: ViewModifier {
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .fill((isPressed ? RepsTheme.Colors.surfacePressed : RepsTheme.Colors.surface).opacity(0.85))
                    .shadow(
                        color: RepsTheme.Shadow.md.color,
                        radius: RepsTheme.Shadow.md.radius,
                        x: RepsTheme.Shadow.md.x,
                        y: RepsTheme.Shadow.md.y
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            // NO GLINT BORDER
    }
}
```

---

## Change 3: "Start Early" Button - NO CHANGES NEEDED ✓

The button at `ContentView.swift:325` already uses `LiquidMetalButtonStyle()` which includes:
- Linear gradient fill (dark → light accent color)
- Animated liquid metal border via Metal shader
- Press state animation
- GPU acceleration with `.drawingGroup()`

This matches the CodePen reference style (chromatic animated border).

---

## Files to Modify

| File | Line(s) | Action |
|------|---------|--------|
| `Views/Components/CustomTabBar.swift` | 63 | Delete `.glintBorder()` call |
| `Views/Components/CustomTabBar.swift` | 68-91 | Add active tab indicator background |
| `Theme/RepsTheme.swift` | 196 | Delete `.glintBorder()` call |

---

## Verification

1. **Build and run on device**
2. **Tab bar**:
   - Active tab should have subtle capsule glow
   - Indicator should NOT move with device tilt
   - Indicator should animate to new tab when switching
3. **Cards**:
   - All cards (Quick Start, Today's Workout, Recent Workouts, etc.) should have NO glint border
   - Shadow and background should remain unchanged
4. **"Start Early" button**:
   - Should have animated chromatic liquid metal border (already working)

---

## References

- [Liquid Metal Button CodePen](https://codepen.io/Majoramari/pen/pvbzpoa) - Reference for button style
- [Apple Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) - iOS 26 design system
