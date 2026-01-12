# Plan: Swipe Navigation, Darker Gradient, Tab Cutoff Fix, Metal Buttons

## Feature 1: Full Swipe Navigation Between Tabs

### Current State
- Edge-only swipe (first/last 40pt of screen) in `ContentView.swift:28-58`
- Uses `highPriorityGesture(DragGesture)` with manual tab switching
- Requires precise edge targeting, not intuitive

### Implementation

**Option A: SwiftUI TabView with PageTabViewStyle** (Recommended)
Replace ZStack+switch with native TabView:

```swift
// ContentView.swift
TabView(selection: $selectedTab) {
    HomeView(onStartWorkout: startWorkout)
        .tag(Tab.home)

    LazyView(ProgramListView())
        .tag(Tab.programs)

    // ... other tabs
}
.tabViewStyle(.page(indexDisplayMode: .never))
.ignoresSafeArea(edges: .bottom)
.overlay(alignment: .bottom) {
    CustomTabBar(selectedTab: $selectedTab)
}
```

Pros: Native swipe, smooth animations, iOS-standard behavior
Cons: May cause view recreation (mitigate with `LazyView`)

**Option B: Custom Gesture with Full-Width Detection**
Keep current approach but remove edge restriction:

```swift
// Remove lines 36-39 edge checks
// Change to: guard abs(horizontal) > vertical * 1.5 else { return }
```

Pros: Keeps current architecture
Cons: Less smooth than native, conflicts with scroll views

### Files to Modify
- `ContentView.swift` - Replace gesture/ZStack with TabView

---

## Feature 2: Darker/More Subtle Background Gradient

### Current State
- Metal shader in `animated-gradient.metal:164` applies `outColor * 0.85`
- Blobs use full brightness colors (e.g., `float3(252/255, 60/255, 0)`)
- Result is vibrant but can distract from content

### Implementation

**Step 1: Add brightness uniform to shader**
```metal
// animated-gradient.metal - Add to Uniforms struct
struct Uniforms {
    float time;
    int page;
    float brightness;  // NEW: 0.0-1.0, default 0.5 for subtler effect
    // ...
};
```

**Step 2: Apply brightness in fragment shader**
```metal
// Line 164 - change from:
outColor = (outColor * 0.85) - (noise * 0.1);
// To:
outColor = (outColor * uniforms.brightness) - (noise * 0.1);
```

**Step 3: Expose brightness in MetalGradientView**
```swift
// MetalGradientView.swift
struct MetalGradientView: UIViewRepresentable {
    var brightness: Float = 0.5  // NEW: default more subtle
    // ... pass to delegate
}
```

### Recommended Values
- Current: `0.85` (very vibrant)
- Subtle: `0.4-0.5` (darker, content-focused)
- Very subtle: `0.25-0.35` (barely visible motion)

### Files to Modify
- `Shaders/animated-gradient.metal` - Add brightness uniform
- `Views/Components/MetalGradientView.swift` - Expose brightness parameter

---

## Feature 3: Fix Tab Screen Content Cutoff

### Current State
Inconsistent bottom padding across tab screens:
- `ProfileView.swift:41` - `.padding(.bottom, 120)` (hardcoded)
- `HistoryListView.swift:76` - `.padding(.bottom, RepsTheme.Spacing.sm)` (8pt)
- `ExerciseLibraryView.swift:66` - `.padding(.bottom, RepsTheme.Spacing.sm)` (8pt)
- `ProgramListView.swift:55` - `.padding(.bottom, RepsTheme.Spacing.sm)` (8pt)

Tab bar height: ~85pt (icon + label + padding + safe area)

### Implementation

**Step 1: Define consistent tab bar clearance**
```swift
// RepsTheme.swift - Add to Constants
struct TabBar {
    static let height: CGFloat = 85  // Actual measured height
    static let contentPadding: CGFloat = 100  // Safe clearance
}
```

**Step 2: Use safeAreaInset instead of padding**
```swift
// Each tab screen ScrollView should use:
ScrollView {
    VStack { /* content */ }
}
.safeAreaInset(edge: .bottom) {
    Color.clear.frame(height: RepsTheme.TabBar.contentPadding)
}
```

**Step 3: Update each tab screen**
- `ProfileView.swift` - Change line 41 from `.padding(.bottom, 120)` to `safeAreaInset`
- `HistoryListView.swift` - Add proper bottom clearance
- `ExerciseLibraryView.swift` - Add proper bottom clearance
- `ProgramListView.swift` - Add proper bottom clearance
- `HomeView` (in ContentView.swift) - Already works but verify

### Files to Modify
- `Theme/RepsTheme.swift` - Add TabBar constants
- `Views/Profile/ProfileView.swift` - Fix bottom padding
- `Views/History/HistoryListView.swift` - Fix bottom padding
- `Views/Exercises/ExerciseLibraryView.swift` - Fix bottom padding
- `Views/Programs/ProgramListView.swift` - Fix bottom padding

---

## Feature 4: Metal Shader Gradient for Primary Buttons

### Current State
- `PrimaryButtonGradient.swift` uses SwiftUI Canvas with 10 ellipse blobs
- Works but doesn't match the Metal shader visual style
- "Start Early", "Start Workout", "+" buttons use `RepsButtonStyle`

### Implementation

**Option A: Reuse Metal Shader (Recommended)**
Create a smaller Metal view for buttons:

```swift
// MetalButtonGradientView.swift - NEW FILE
struct MetalButtonGradientView: UIViewRepresentable {
    var palette: Palette?
    var speed: Float = 1.2  // Slightly faster for button energy
    var brightness: Float = 0.6  // Brighter than bg, darker than current

    // Same implementation as MetalGradientView but:
    // - Smaller drawable size
    // - Higher brightness for button prominence
    // - Optional: different blob positions for variety
}
```

**Option B: Adapt Existing Metal Shader**
Add a "mode" uniform to existing shader:
- Mode 0: Full background (current)
- Mode 1: Button variant (tighter blobs, higher brightness)

### Button Style Integration
```swift
// GradientButtonStyle update
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            MetalButtonGradientView()
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))

            // Dark overlay for text contrast
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .fill(Color.black.opacity(0.15))

            configuration.label
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(.white)
        }
        .frame(height: 50)
    }
}
```

### Buttons to Update
- "Start Workout" button in `ScheduledWorkoutCard`
- "Start Early" button in `NextWorkoutCard`
- "+" button in `QuickStartCard` (if desired)
- Any `.buttonStyle(RepsButtonStyle(style: .primary))` usage

### Files to Modify/Create
- NEW: `Views/Components/MetalButtonGradientView.swift`
- UPDATE: `Views/Components/PrimaryButtonGradient.swift` - Replace Canvas with Metal

---

## Implementation Order

1. **Darker Gradient** (lowest risk, immediate visual impact)
2. **Tab Cutoff Fix** (consistent UX, no architecture change)
3. **Metal Buttons** (visual enhancement, contained scope)
4. **Swipe Navigation** (higher risk, test thoroughly)

---

## Unresolved Questions

1. Swipe: Use native TabView or keep custom gesture?
2. Brightness: What exact value (0.4, 0.5, 0.6)?
3. Buttons: Reuse MetalGradientView or create separate shader?
4. Swipe conflicts: How to handle horizontal ScrollViews in tabs?
