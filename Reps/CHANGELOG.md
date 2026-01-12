# Reps UI Changelog

## [Unreleased] - AnyDistance-Inspired UI Overhaul

### Design System Foundation

#### Theme (`RepsTheme.swift`)
- **Colors**: Pure black background, #FF5500 (TE Orange) accent, gradient stops for progress indicators
- **Typography**: Monospaced fonts for metrics (.monospaced), rounded for headers (.rounded)
- **Animations**: Premium smooth curve (0.36, 0.33, 0.28, 1.06), spring responses for buttons
- **Spacing**: Standardized xxs(4) through xxxl(48)
- **Radius**: Standardized sm(8) through full(9999)

#### Button Styles
- `ScalingPressButtonStyle`: 0.95 scale, 0.8 opacity on press with spring animation
- `ScalingPressWithHapticButtonStyle`: Same + haptic feedback

### Core Components Created

| Component | File | Purpose |
|-----------|------|---------|
| `ADFilterChip` | `ADFilterChip.swift` | Horizontal scrolling filter pills |
| `StatMetricCard` | `StatMetricCard.swift` | 2x2 metric grid display |
| `GradientProgressBar` | `GradientProgressBar.swift` | Linear progress with gradient fill |
| `CircularProgressRing` | `CircularProgressRing.swift` | Circular completion indicator |
| `CumulativeProgressChart` | `CumulativeProgressChart.swift` | Volume over time with YoY comparison |
| `DarkBlurView` | `DarkBlurView.swift` | UIVisualEffectView wrapper |
| `ToastView` | `ToastView.swift` | Floating notifications |
| `AnimatedGradientView` | `AnimatedGradientView.swift` | Pure SwiftUI animated backgrounds |

### View Overhauls

#### ProfileView
- 2x2 stats grid with large monospace numbers
- Cumulative volume chart (lime green line) with dashed YoY comparison
- Contribution graph with orange intensity gradient
- Dark card backgrounds (#1C1C1E)

#### PersonalRecordsView
- ADFilterChip horizontal filter row
- Time-grouped sections ("Today", "Yesterday", "This Week", etc.)
- Dark cards with accent highlights

#### ExerciseLibraryView
- Two FilterChip rows (Muscles + Equipment)
- Pure black background
- Dark card cells with muscle group badges

#### ContributionGraphView
- Orange intensity gradient (was green)
- Dark card background
- Improved label styling

### Advanced Features

#### Magic Palettes (`Palette.swift`, `PaletteManager.swift`)
- 6 preset palettes: Dark, Midnight, Forest, Ocean, Sunset, Ember
- Photo color extraction via dominant color analysis
- Dynamic theme switching throughout app
- ThemeSettingsView with live preview

#### Transitions (`Transitions.swift`)
- `scaleUp`, `slideUp`, `slideIn` custom transitions
- `ShimmerModifier` for loading states
- `PulseModifier` for recording indicators
- `GlowModifier` for accent highlights
- `blurFade` composite transition

#### Haptics (`HapticManager.swift`)
- Selection feedback on filter changes
- Medium impact on button presses
- Success notification on PR achievements

### Files Created
```
Views/Components/
├── ADFilterChip.swift
├── AnimatedGradientView.swift
├── ChartAnimations.swift          # NEW: Pulsing dots, animated lines, tooltips
├── CircularProgressRing.swift
├── CustomTabBar.swift
├── DarkBlurView.swift             # Enhanced: BlurOpacityTransition
├── EmptyStateView.swift           # NEW: Preset empty states
├── GradientProgressBar.swift
├── ParallaxCard.swift             # NEW: Motion-based parallax
├── PRTimelineCard.swift
├── ScalingPressButtonStyle.swift
├── SkeletonView.swift             # NEW: Loading skeletons
├── StatMetricCard.swift
├── TimelineRuler.swift
├── ToastView.swift
├── VolumeExerciseRow.swift
└── WeekPicker.swift

Views/Profile/
├── CumulativeProgressChart.swift
├── PRHistoryTimelineView.swift
├── ThemeSettingsView.swift
└── VolumeBreakdownView.swift

Models/
└── Palette.swift

Utils/
├── HapticManager.swift
├── LazyView.swift
├── PaletteManager.swift
├── SoundPlayer.swift              # NEW: Audio feedback
└── Transitions.swift

Theme/
└── RepsTheme.swift                # Enhanced: Reduced motion support
```

### AnyDistance Insights Applied
- BlurOpacityTransition with configurable timing
- Staggered animations with index-based delays
- Pulsing dot animation for chart data points
- Smooth curve interpolation for line charts
- Parallax effect with CoreMotion
- Floating card animations
- Breathing glow effects
- Skeleton loading states
- Sound player for celebrations
- Reduced motion support

### Testing Notes
- **Always use `describe_ui`** with xcodebuildmcp for precise element coordinates
- Don't guess coordinates from screenshots
- Verified on iPhone 17 Pro simulator

### Reference
- AnyDistance (2023 Apple Design Award winner) patterns
- Plan file: `.claude/plans/async-imagining-storm.md`
