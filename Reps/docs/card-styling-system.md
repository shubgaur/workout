# Card Styling System

## Overview

All cards across the app use the `.repsCard()` modifier for consistent visual styling. This ensures uniform appearance and makes it easy to update the design system in one place.

---

## The `.repsCard()` Modifier

Location: `Reps/Theme/RepsTheme.swift`

```swift
extension View {
    func repsCard(isPressed: Bool = false) -> some View {
        modifier(RepsCardStyle(isPressed: isPressed))
    }
}

struct RepsCardStyle: ViewModifier {
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .fill(isPressed ? RepsTheme.Colors.surfacePressed : RepsTheme.Colors.surface)
                    .shadow(
                        color: RepsTheme.Shadow.md.color,
                        radius: RepsTheme.Shadow.md.radius,
                        x: RepsTheme.Shadow.md.x,
                        y: RepsTheme.Shadow.md.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
    }
}
```

---

## Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `RepsTheme.Radius.md` | 12pt | Corner radius |
| `RepsTheme.Colors.surface` | Dark surface color | Card background |
| `RepsTheme.Colors.surfacePressed` | Lighter surface | Pressed state |
| `RepsTheme.Shadow.md` | Black 40%, 4pt blur, 0x2 offset | Card shadow |
| `RepsTheme.Colors.border` | Subtle border color | 1pt stroke |
| `RepsTheme.Spacing.md` | 16pt | Internal padding |
| `RepsTheme.Spacing.sm` | 8pt | Spacing between cards |

---

## Card Layout Pattern

Every card follows this structure:

```swift
// Content inside the card
HStack/VStack {
    // Card content...
}
.padding(RepsTheme.Spacing.md)  // Internal padding
.repsCard()                      // Apply card styling
```

### With NavigationLink

```swift
NavigationLink(destination: DetailView()) {
    CardContent()
        .padding(RepsTheme.Spacing.md)
        .repsCard()
}
.buttonStyle(ScalingPressButtonStyle())  // Press animation
```

---

## List-to-Card Conversion

Cards are displayed in `ScrollView` + `LazyVStack`, not `List`:

```swift
ScrollView {
    LazyVStack(spacing: RepsTheme.Spacing.sm) {
        ForEach(items) { item in
            NavigationLink(destination: DetailView(item: item)) {
                ItemRow(item: item)
                    .padding(RepsTheme.Spacing.md)
                    .repsCard()
            }
            .buttonStyle(ScalingPressButtonStyle())
            .contextMenu {
                // Context menu items...
            }
        }
    }
    .padding(.horizontal, RepsTheme.Spacing.md)
    .padding(.bottom, RepsTheme.Spacing.lg)
}
.scrollContentBackground(.hidden)
.background(Color.clear)
```

**Why ScrollView over List:**
- Cards have rounded corners and shadows (List clips these)
- Consistent spacing control
- Works with transparent backgrounds
- Context menus still work

**Trade-off:** Swipe actions are lost (List-only feature)

---

## Files Using Card System

| File | Component | Notes |
|------|-----------|-------|
| `ContentView.swift` | QuickStartCard, TodayWorkoutCard, etc. | Home page cards |
| `ProgramListView.swift` | ProgramRow | Program list items |
| `ExerciseLibraryView.swift` | ExerciseCell | Exercise list items |
| `HistoryListView.swift` | WorkoutHistoryCell | Workout history items |
| `ProfileView.swift` | StatMetricCard, MenuRow, Chart | Profile stats and menu |
| `StatMetricCard.swift` | StatMetricCard | 2x2 metric grid cards |

---

## Card Content Guidelines

### Standard Card Row

```swift
struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Icon/Image (48x48)
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(RepsTheme.Colors.surfaceElevated)
                    .frame(width: 48, height: 48)
                Image(systemName: "icon.name")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Text content
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(item.title)
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text(item.subtitle)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Spacer()

            // Chevron (for navigation)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        // Note: NO padding here - parent adds it
    }
}
```

### Badges/Tags Inside Cards

```swift
Text("ACTIVE")
    .font(.system(size: 9, weight: .bold, design: .monospaced))
    .foregroundStyle(RepsTheme.Colors.accent)
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(
        RoundedRectangle(cornerRadius: 4)
            .fill(RepsTheme.Colors.accent.opacity(0.2))
    )
```

---

## Modifying Card Appearance

To change card appearance globally, edit `RepsCardStyle` in `RepsTheme.swift`:

```swift
struct RepsCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(/* change background */)
            .overlay(/* change border */)
    }
}
```

Changes will apply to all cards using `.repsCard()`.

---

## Press Animation

Cards use `ScalingPressButtonStyle` for press feedback:

```swift
struct ScalingPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
```

Location: `Reps/Views/Components/ScalingPressButtonStyle.swift`
