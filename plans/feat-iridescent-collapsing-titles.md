# feat: Iridescent Collapsing Page Titles

## Overview

Implement scroll-aware iridescent (holographic) titles for all 5 main pages: Home, Exercises, Programs, History, and Profile. Titles will collapse/slide up on scroll down, reappear with moderate scroll-up threshold, and feature blur/glass backgrounds for readability.

**Reference:** Any Distance app implementation uses `GradientEffect` modifier with `LinearGradient` + `MotionManager.roll` for tilt-responsive rainbow effect. This codebase already has a more advanced GPU-accelerated `HolographicText` component using Metal shaders.

## Problem Statement

Currently:
- **HomeView** uses plain `Text("Reps")` - NOT iridescent (line 130-132 in `ContentView.swift`)
- Other pages (Exercises, Programs, History, Profile) already use `GradientTitle` (alias for `HolographicText`)
- **No scroll-aware collapsing behavior** exists on any page
- Titles are static within `.safeAreaInset(edge: .top)` blocks

Users want premium-feeling page titles that:
1. Shimmer with device motion (all pages should have this)
2. Collapse out of view when scrolling down to maximize content space
3. Reappear when scrolling back up for easy navigation context
4. Have subtle glass backgrounds for readability over dynamic content

## Proposed Solution

Create a reusable `CollapsingIridescentHeader` component that wraps `HolographicText` with scroll-aware show/hide behavior, then apply it to all 5 main pages.

### Technical Approach

1. **Scroll Detection:** iOS 17+ `onScrollGeometryChange` API (primary), with PreferenceKey fallback structure for future iOS 16 support if needed
2. **Animation:** Spring animation (response: 0.35, dampingFraction: 0.85) for collapse/expand
3. **Background:** `.ultraThinMaterial` full-width blur bar
4. **Accessibility:** Respect `accessibilityReduceMotion` - disable TimelineView animation and parallax

## Technical Considerations

### Architecture

- **New Component:** `CollapsingIridescentHeader.swift` in `Views/Components/`
- **Reuses:** `HolographicText`, `MotionManager.shared`, `DarkBlurView` patterns
- **Scroll Tracking:** New `ScrollOffsetPreferenceKey` for backward compatibility

### Performance

- Metal shaders are GPU-accelerated via `.drawingGroup()`
- TimelineView runs at 30fps (not 60) to balance smoothness vs battery
- Motion updates are reference-counted (stop when no subscribers)
- Low Power Mode reduces motion updates to 30Hz

### Accessibility

- `accessibilityReduceMotion`: Disable TimelineView, remove parallax rotation
- VoiceOver: Title remains in accessibility tree even when visually collapsed

## Acceptance Criteria

### Functional Requirements

- [ ] All 5 pages (Home, Exercises, Programs, History, Profile) display iridescent titles
- [ ] Titles respond to device tilt with rainbow color shift
- [ ] Scrolling down collapses title (slides up out of view)
- [ ] Scrolling up by threshold (~50pt) reveals title again
- [ ] At scroll position 0 (top), title is always visible
- [ ] Blur/glass background behind title ensures readability

### Non-Functional Requirements

- [ ] Animation maintains 60fps on iPhone 12 and newer
- [ ] Respects Reduce Motion accessibility setting
- [ ] Works on iOS 17+ (primary target)
- [ ] No visual conflicts with `.searchable()` on ExerciseLibraryView

### Quality Gates

- [ ] Test on physical device (simulator lacks CoreMotion)
- [ ] Test with Reduce Motion enabled
- [ ] Test all 5 pages scroll behavior
- [ ] Test tab switching preserves scroll state

## Implementation Phases

### Phase 1: Create CollapsingIridescentHeader Component

**Deliverables:**
- New file: `Reps/Reps/Views/Components/CollapsingIridescentHeader.swift`

**Tasks:**
1. Create `ScrollOffsetPreferenceKey` for scroll tracking
2. Build `CollapsingIridescentHeader` view with:
   - `title: String` parameter
   - `@Binding var isVisible: Bool` for external control
   - Optional `trailingContent` ViewBuilder for action buttons
3. Integrate scroll detection via `onScrollGeometryChange` (iOS 17+)
4. Add collapse/expand spring animation
5. Add `.ultraThinMaterial` background
6. Add accessibility support (reduceMotion)

**File structure:**
```swift
// CollapsingIridescentHeader.swift

import SwiftUI

// MARK: - Scroll Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey { ... }

// MARK: - Collapsing Iridescent Header
struct CollapsingIridescentHeader<TrailingContent: View>: View {
    let title: String
    let trailingContent: () -> TrailingContent

    @State private var isHeaderVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var accumulatedScrollUp: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let scrollUpThreshold: CGFloat = 50
    private let headerHeight: CGFloat = 78

    var body: some View { ... }
}

extension CollapsingIridescentHeader where TrailingContent == EmptyView {
    init(title: String) { ... }
}
```

**Success criteria:**
- Component renders iridescent title with blur background
- Scroll detection triggers collapse/expand
- Reduce Motion disables animation

---

### Phase 2: Update HomeView with Iridescent Title

**Deliverables:**
- Update `ContentView.swift` HomeView to use `GradientTitle` instead of plain `Text`

**Tasks:**
1. Replace `Text("Reps")` with `GradientTitle(text: "Reps")` at line 130
2. Ensure padding/spacing matches other pages (`.padding(.top, RepsTheme.Spacing.xl)`)
3. Test iridescent effect with device motion

**Current code (ContentView.swift:127-138):**
```swift
.safeAreaInset(edge: .top) {
    HStack {
        Text("Reps")
            .font(RepsTheme.Typography.largeTitle)
            .foregroundStyle(RepsTheme.Colors.text)
        Spacer()
    }
    .padding(.horizontal, RepsTheme.Spacing.md)
    .padding(.top, RepsTheme.Spacing.md)  // Should be .xl
    .padding(.bottom, RepsTheme.Spacing.sm)
}
```

**Updated code:**
```swift
.safeAreaInset(edge: .top) {
    HStack {
        GradientTitle(text: "Reps")
        Spacer()
    }
    .padding(.horizontal, RepsTheme.Spacing.md)
    .padding(.top, RepsTheme.Spacing.xl)
    .padding(.bottom, RepsTheme.Spacing.sm)
}
```

**Success criteria:**
- HomeView title shimmers with device tilt
- Visual consistency with other pages

---

### Phase 3: Apply Collapsing Behavior to All Pages

**Deliverables:**
- Refactor all 5 main views to use `CollapsingIridescentHeader`

**Tasks:**
1. **HomeView** (`ContentView.swift:105-140`):
   - Wrap ScrollView content with scroll tracking
   - Replace safeAreaInset title with CollapsingIridescentHeader

2. **ExerciseLibraryView** (`ExerciseLibraryView.swift:44-59`):
   - Add scroll tracking to existing ScrollView
   - Use CollapsingIridescentHeader with filter button as trailing content
   - Handle interaction with `.searchable()` modifier

3. **ProgramListView** (`ProgramListView.swift:34-42`):
   - Add scroll tracking to programsList ScrollView
   - Replace safeAreaInset with CollapsingIridescentHeader

4. **HistoryListView** (`HistoryListView.swift:63-71`):
   - Add scroll tracking to workoutList ScrollView
   - Use CollapsingIridescentHeader (title only, no trailing content)

5. **ProfileView** (`ProfileView.swift:45-54`):
   - Add scroll tracking to main ScrollView
   - Replace safeAreaInset with CollapsingIridescentHeader

**Pattern to apply (example for ProgramListView):**
```swift
// Before
ScrollView {
    LazyVStack { ... }
}
.safeAreaInset(edge: .top) {
    HStack {
        GradientTitle(text: "Programs")
        Spacer()
    }
    .padding(...)
}

// After
ScrollView {
    LazyVStack { ... }
}
.onScrollGeometryChange(for: CGFloat.self) { geo in
    geo.contentOffset.y + geo.contentInsets.top
} action: { old, new in
    handleScrollChange(old: old, new: new)
}
.safeAreaInset(edge: .top, spacing: 0) {
    CollapsingIridescentHeader(title: "Programs")
        .offset(y: isHeaderVisible ? 0 : -headerHeight)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: isHeaderVisible)
}
```

**Success criteria:**
- All 5 pages have collapsing titles
- Consistent behavior across pages
- No regressions in existing functionality

---

### Phase 4: Polish and Edge Cases

**Deliverables:**
- Handle edge cases and polish interactions

**Tasks:**
1. **Empty State Handling:**
   - When content is too short to scroll, title remains static
   - Detect via content size comparison

2. **Tab Switching:**
   - Each tab maintains independent scroll/title state
   - Title resets to visible when switching tabs (optional)

3. **Navigation Push/Pop:**
   - Title state preserved when pushing detail views
   - State restored on pop

4. **Searchable Interaction (ExerciseLibraryView):**
   - Coordinate title collapse with search bar behavior
   - Title collapses first, search bar remains accessible

5. **Low Power Mode:**
   - Reduce TimelineView updates or disable animation
   - Keep static gradient appearance

**Success criteria:**
- No visual glitches in edge cases
- Smooth interaction with system UI elements

## Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `Reps/Reps/Views/Components/CollapsingIridescentHeader.swift` | Reusable collapsing header component |

### Modified Files
| File | Changes |
|------|---------|
| `Reps/Reps/ContentView.swift:127-138` | HomeView: Replace Text with GradientTitle, add scroll tracking |
| `Reps/Reps/Views/Exercises/ExerciseLibraryView.swift:44-59` | Add scroll tracking, use CollapsingIridescentHeader |
| `Reps/Reps/Views/Programs/ProgramListView.swift:34-42` | Add scroll tracking, use CollapsingIridescentHeader |
| `Reps/Reps/Views/History/HistoryListView.swift:63-71` | Add scroll tracking, use CollapsingIridescentHeader |
| `Reps/Reps/Views/Profile/ProfileView.swift:45-54` | Add scroll tracking, use CollapsingIridescentHeader |

## Dependencies & Prerequisites

### Internal Dependencies
- `HolographicText.swift` - Existing iridescent text component
- `MotionManager.swift` - Device motion tracking
- `RepsTheme.swift` - Spacing and animation values
- `DarkBlurView.swift` - Blur view patterns

### External Dependencies
- iOS 17+ for `onScrollGeometryChange` API
- CoreMotion framework (already in use)
- Metal shaders (already compiled)

## Risk Analysis & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| iOS 16 users can't use feature | Low | Medium | Feature only activates on iOS 17+; title remains static on iOS 16 |
| Performance issues on older devices | Medium | High | Test on iPhone 12; reduce animation complexity if needed |
| Conflicts with searchable modifier | Medium | Medium | Test ExerciseLibraryView thoroughly; adjust z-ordering if needed |
| Motion sickness from iridescent effect | Low | Low | Already handled via Reduce Motion accessibility |

## Success Metrics

1. **User Experience:** Titles collapse/expand smoothly without jitter
2. **Performance:** 60fps maintained during scroll animations
3. **Accessibility:** Full functionality with Reduce Motion enabled
4. **Consistency:** All 5 pages behave identically

## References

### Internal References
- `Reps/Reps/Views/Components/HolographicText.swift` - Base iridescent component
- `Reps/Reps/Utils/MotionManager.swift` - Motion tracking
- `Reps/Reps/Shaders/holographic-text.metal` - Metal shader
- `Reps/Reps/Views/Components/DarkBlurView.swift` - Blur patterns

### External References
- [Apple: onScrollGeometryChange](https://developer.apple.com/documentation/swiftui/view/onscrollgeometrychange)
- [Apple: Material](https://developer.apple.com/documentation/swiftui/material)
- [Swift with Majid: Mastering ScrollView](https://swiftwithmajid.com/2024/06/25/mastering-scrollview-in-swiftui-scroll-geometry/)
- [Any Distance App Iridescence Implementation](pasted_text_2026-01-12_14-42-30.txt)

### Related Work
- PR #1: Liquid metal UI implementation

---

## MVP: CollapsingIridescentHeader Component

### CollapsingIridescentHeader.swift

```swift
import SwiftUI

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Collapsing Iridescent Header

/// A scroll-aware header with iridescent title that collapses on scroll down
/// and reappears on scroll up. Uses blur/glass background for readability.
struct CollapsingIridescentHeader<TrailingContent: View>: View {
    let title: String
    @ViewBuilder let trailingContent: () -> TrailingContent

    @State private var isHeaderVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var accumulatedScrollUp: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Configuration
    private let scrollUpThreshold: CGFloat = 50
    private let hideThreshold: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HolographicText(text: title)
                Spacer()
                trailingContent()
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.xl)
            .padding(.bottom, RepsTheme.Spacing.sm)
            .background(.ultraThinMaterial)
        }
        .offset(y: isHeaderVisible ? 0 : -100)
        .opacity(isHeaderVisible ? 1 : 0)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85),
            value: isHeaderVisible
        )
    }

    // Call this from onScrollGeometryChange action
    func handleScroll(oldOffset: CGFloat, newOffset: CGFloat) {
        let delta = newOffset - oldOffset

        // At or near top - always show
        if newOffset <= 10 {
            if !isHeaderVisible {
                setHeaderVisible(true)
            }
            accumulatedScrollUp = 0
            return
        }

        // Scrolling up
        if delta < 0 {
            accumulatedScrollUp += abs(delta)
            if accumulatedScrollUp >= scrollUpThreshold && !isHeaderVisible {
                setHeaderVisible(true)
            }
        }
        // Scrolling down
        else if delta > 0 {
            accumulatedScrollUp = 0
            if newOffset > hideThreshold && isHeaderVisible {
                setHeaderVisible(false)
            }
        }
    }

    private func setHeaderVisible(_ visible: Bool) {
        if reduceMotion {
            isHeaderVisible = visible
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isHeaderVisible = visible
            }
        }
    }
}

// MARK: - Convenience Initializer

extension CollapsingIridescentHeader where TrailingContent == EmptyView {
    init(title: String) {
        self.title = title
        self.trailingContent = { EmptyView() }
    }
}
```

---

## Test Plan

- [ ] **Scroll down on each page** - Title should collapse (slide up)
- [ ] **Scroll up ~50pt on each page** - Title should reappear
- [ ] **Scroll to top** - Title always visible
- [ ] **Tilt device** - Iridescent color shift
- [ ] **Enable Reduce Motion** - No animation, static colors
- [ ] **Switch tabs** - Each tab has independent state
- [ ] **Push/pop navigation** - State preserved
- [ ] **ExerciseLibraryView search** - Title and search bar don't conflict
- [ ] **Empty states** - Title remains static when no content
- [ ] **Low Power Mode** - Reduced animation overhead
