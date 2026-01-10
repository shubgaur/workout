# Transparent NavigationStack Background for Shared Gradient

## Problem

When using a single shared `MetalGradientView` at the root of `ContentView` with HStack-based tab paging:
- NavigationStack's internal UIKit views have opaque backgrounds
- iOS 16+ List uses UICollectionView internally (not UITableView)
- SwiftUI re-applies backgrounds during state updates
- Result: Black background visible on tabs, jarring edge during swipe transitions

## Solution Architecture

```
ContentView
├── ZStack
│   ├── MetalGradientView (SHARED - always visible, ignoresSafeArea)
│   │
│   └── HStack (all 5 tabs side-by-side, each with .transparentNavigation())
│       ├── HomeView.frame(width: screenWidth)
│       ├── ProgramListView.frame(width: screenWidth)
│       ├── ExerciseLibraryView.frame(width: screenWidth)
│       ├── HistoryListView.frame(width: screenWidth)
│       └── ProfileView.frame(width: screenWidth)
│
└── CustomTabBar (overlay at bottom)
```

## Key Implementation

### 1. ClearNavigationBackground.swift

Location: `Reps/Utils/ClearNavigationBackground.swift`

```swift
import SwiftUI
import UIKit

struct ClearNavigationBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        InnerClearView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? InnerClearView)?.clearBackgrounds()
    }

    private class InnerClearView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            clearBackgrounds()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            clearBackgrounds()
        }

        func clearBackgrounds() {
            // Clear every view in the superview chain up to the window
            var current: UIView? = self
            while let view = current {
                view.backgroundColor = .clear
                view.isOpaque = false
                view.layer.backgroundColor = nil
                current = view.superview
            }

            // Also clear the window itself
            window?.backgroundColor = .clear
            window?.isOpaque = false

            // Find and clear all UICollectionViews and UITableViews in the hierarchy
            if let root = window?.rootViewController?.view {
                clearScrollableViews(in: root)
            }
        }

        private func clearScrollableViews(in view: UIView) {
            if view is UICollectionView || view is UITableView || view is UIScrollView {
                view.backgroundColor = .clear
                view.isOpaque = false
                view.layer.backgroundColor = nil
            }

            let className = String(describing: type(of: view))
            if className.hasPrefix("_") || className.contains("Hosting") ||
               className.contains("Controller") || className.contains("Container") {
                view.backgroundColor = .clear
                view.isOpaque = false
            }

            for subview in view.subviews {
                clearScrollableViews(in: subview)
            }
        }
    }
}

extension View {
    func transparentNavigation() -> some View {
        self
            .background(ClearNavigationBackground())
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
```

### 2. Apply to Each Tab View

Each tab's NavigationStack content must use `.transparentNavigation()`:

```swift
struct ProgramListView: View {
    var body: some View {
        NavigationStack {
            Group {
                // content...
            }
            .transparentNavigation()  // <-- Apply here
            // ...
        }
    }
}
```

### 3. Additional SwiftUI Modifiers Required

On List/ScrollView content:
```swift
.scrollContentBackground(.hidden)
.background(Color.clear)
```

On List rows:
```swift
.listRowBackground(RepsTheme.Colors.surface)  // or Color.clear
```

### 4. RepsApp.swift UIKit Appearance (Supporting)

```swift
// In init()
UIView.appearance().backgroundColor = .clear

let navAppearance = UINavigationBarAppearance()
navAppearance.configureWithTransparentBackground()
navAppearance.backgroundColor = .clear
UINavigationBar.appearance().standardAppearance = navAppearance
UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
```

## Why This Works

1. **Lifecycle hooks**: `didMoveToWindow()` and `layoutSubviews()` catch when SwiftUI re-applies backgrounds
2. **Superview chain traversal**: Clears ALL views up to window, not just immediate parent
3. **Pattern matching**: Targets UIKit internal classes by name pattern (`_`, `Hosting`, `Controller`, `Container`)
4. **Scroll view targeting**: Explicitly clears UICollectionView/UITableView (iOS 16+ List internals)

### 5. Sub-Pages (Pushed Views) Need `.transparentNavigation()` Too

**Critical**: Views pushed onto NavigationStack also need `.transparentNavigation()`. Using only `.scrollContentBackground(.hidden)` + `.background(Color.clear)` is NOT sufficient—pushed views get their own UIKit container views that need clearing.

```swift
// ❌ WRONG - sub-page shows black background
struct SettingsView: View {
    var body: some View {
        List { ... }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
    }
}

// ✅ CORRECT - gradient shows through
struct SettingsView: View {
    var body: some View {
        List { ... }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .transparentNavigation()
    }
}
```

**Sub-pages requiring `.transparentNavigation()`:**
- Profile: SettingsView, ThemeSettingsView, PRHistoryTimelineView, VolumeBreakdownView
- History: WorkoutDetailView, PersonalRecordsView
- Exercises: ExerciseDetailView
- Programs: ProgramDetailView, PhaseDetailView, WeekDetailView, DayDetailView

### 6. Scroll Extent for Tab Bar

Main tab views need `.padding(.bottom, 70)` so content isn't cut off by the custom tab bar:

```swift
ScrollView {
    VStack { ... }
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.bottom, 70)  // <-- Tab bar height
}
```

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Black background on List | UICollectionView has opaque background | `clearScrollableViews` handles this |
| Background reappears on state change | SwiftUI re-applies during updates | `layoutSubviews` hook re-clears |
| Navigation bar has background | Toolbar appearance not cleared | `.toolbarBackground(.hidden)` |
| Sub-page has black background | Pushed view has own UIKit containers | Use `.transparentNavigation()` on sub-pages |
| Content cut off by tab bar | Insufficient bottom padding | Add `.padding(.bottom, 70)` |

## Files Modified

- `Reps/Utils/ClearNavigationBackground.swift` - Created
- `Reps/Views/Programs/ProgramListView.swift` - Added `.transparentNavigation()`
- `Reps/Views/Exercises/ExerciseLibraryView.swift` - Added `.transparentNavigation()`
- `Reps/Views/History/HistoryListView.swift` - Added `.transparentNavigation()`
- `Reps/Views/Profile/ProfileView.swift` - Added `.transparentNavigation()`
- `Reps/ContentView.swift` - Single shared MetalGradientView at root

## Result

- Single Metal pipeline instead of 5 (memory efficient)
- No init delay when switching tabs
- Seamless swipe transitions with continuous gradient
- No black edges or jarring visual artifacts
