# Reps - iOS Workout Tracker

## Quick Reference

- **Platform**: iOS 17+ / SwiftUI / SwiftData
- **Bundle ID**: `com.shubgaur.reps`
- **iPhone**: 16 Pro Max, CoreDevice `48CAF11A-3CC0-546A-91FA-B4CCAEF6D72E`, device ID `00008140-000A4D841A13001C`
- **Build & Deploy**:
  ```bash
  cd Reps && xcodebuild -project Reps.xcodeproj -scheme Reps -destination 'id=00008140-000A4D841A13001C' -allowProvisioningUpdates build
  xcrun devicectl device install app --device 48CAF11A-3CC0-546A-91FA-B4CCAEF6D72E <path-to-.app>
  xcrun devicectl device process launch --device 48CAF11A-3CC0-546A-91FA-B4CCAEF6D72E com.shubgaur.reps
  ```
- **Build output**: `~/Library/Developer/Xcode/DerivedData/Reps-cottnjbaibvjlighpupsvdljhjoq/Build/Products/Debug-iphoneos/Reps.app`

## Architecture

### Data Layer (SwiftData @Model)
```
Program → Phase → Week → ProgramDay → WorkoutTemplate → ExerciseGroup → WorkoutExercise → SetTemplate
                                                                                        ↘ LoggedSet (live workout)
Exercise (standalone library, linked via WorkoutExercise.exercise)
PersonalRecord (linked to Exercise + LoggedSet)
WorkoutSession (linked to WorkoutTemplate + ProgramDay, owns ExerciseGroups)
UserSettings (singleton), UserStats (singleton)
```

All relationships use `@Relationship(deleteRule: .cascade)` for parent→child. Sorted accessors on every model (`sortedPhases`, `sortedWeeks`, etc.) use the `order`/`weekNumber`/`dayNumber`/`setNumber` properties.

### Services
- **ExerciseService**: Seeds from `exercises.json`, CRUD, fuzzy name search. Syncs `bundledVideoFilename` on every launch.
- **ImportService**: JSON→SwiftData import via DTO pattern (ProgramDTO, PhaseDTO, WeekDTO, DayDTO, WorkoutDTO, ExerciseGroupDTO, WorkoutExerciseDTO, SetDTO). All builder methods are `internal` (not private).
- **SampleDataService**: Seeds sample data + BBR program from `bbr-program.json` via ImportService.
- **ScheduleService**: Static methods for program scheduling, skip/pause/resume, day advancement.
- **VideoStorageService**: Manages user-uploaded videos in Documents/videos/.

### Key Patterns
- **Video URL resolution**: `Exercise.effectiveVideoURL` → local file > bundled video > nil (never falls back to remote `videoURL`)
- **Bundled videos**: 15 compressed MP4s in `Resources/Videos/` folder reference. `Bundle.main.url(forResource:withExtension:subdirectory:"Videos")`
- **Per-side sets**: `SetSide` enum (.left/.right) on both `SetTemplate` and `LoggedSet`. ExerciseCard groups sets by side.
- **Program import JSON**: See `bbr-program.json` for the canonical format with `side`, `isOptional`, `notes`, `programDetails` fields.
- **Sheet pattern**: Use `@Bindable var` for editing models in sheets, `@State` booleans for presentation.
- **Context menu**: Used for delete actions (NOT swipe-to-delete).
- **Onboarding**: `@AppStorage("hasSeenOnboarding")` gates a `.fullScreenCover(OnboardingView)` in ContentView.

### Design System (RepsTheme)
- **Accent**: `#FF5500` (Teenage Engineering Orange)
- **Typography**: `.rounded` design for all text, monospaced for metrics
- **Cards**: `.repsCard()` modifier (surface bg, rounded corners, shadow)
- **Buttons**: `RepsButtonStyle(.primary/.secondary/.ghost)`, `LiquidMetalButtonStyle`
- **Navigation**: `.transparentNavigation()` modifier, `CollapsingIridescentHeader` for tab roots
- **Metal shaders**: animated-gradient, holographic-text, liquid-metal-border

## Critical Gotchas

### SourceKit False Positives
SourceKit LSP diagnostics like "Cannot find 'RepsTheme' in scope" or "Cannot find type 'Program' in scope" are **FALSE POSITIVES**. The project builds and runs successfully. Do not attempt to "fix" these - they are an Xcode/SourceKit indexing issue.

### Exercise Seeding & Video Filenames
Exercises are seeded once from `exercises.json`. If you add `bundledVideoFilename` to exercises.json AFTER initial seeding, existing exercises in the database won't have it. The `syncBundledVideoFilenames()` method in ExerciseService handles this by updating existing exercises on every launch. If you add new video fields to exercises, this sync will propagate them.

### pbxproj File IDs
New files need 4 entries in `project.pbxproj`:
1. **PBXBuildFile** section: `{ID}1 /* File.swift in Sources */`
2. **PBXFileReference** section: `{ID}0 /* File.swift */`
3. **PBXGroup children**: Add file ref to the appropriate group
4. **PBXSourcesBuildPhase files** (for .swift) or **PBXResourcesBuildPhase files** (for .json, assets, folders)

Convention: IDs follow pattern `E80000002D4A00000000XXXX` (file ref) / `E80000012D4A00000000XXXX` (build file). Next available: `002E`.

### Folder References vs Groups
The `Videos/` directory is added as a **folder reference** (`lastKnownFileType = folder`), NOT a group. This preserves the directory structure in the bundle. Use `Bundle.main.url(forResource:withExtension:subdirectory:"Videos")` to access.

### ContentView Deep Copy
When starting a workout from a template, ContentView deep-copies the entire ExerciseGroup→WorkoutExercise→LoggedSet tree from the template into the WorkoutSession. Changes to logged sets don't affect templates.

### Phone Must Be Unlocked
`xcrun devicectl device process launch` fails if the phone is locked with error `FBSOpenApplicationErrorDomain error 7`. User must unlock first.

## File Organization

```
Reps/
├── RepsApp.swift              # App entry, SwiftData container, seeding
├── ContentView.swift          # Tab bar, HomeView, workout cards, deep copy
├── Models/                    # @Model classes + Enums
├── Services/                  # ExerciseService, ImportService, SampleDataService, ScheduleService, VideoStorageService
├── Theme/RepsTheme.swift      # Colors, Typography, Spacing, Radius, Shadows, Animations
├── Resources/
│   ├── exercises.json         # Exercise library (40+ exercises)
│   ├── bbr-program.json       # BBR program definition (4 phases)
│   └── Videos/                # 15 compressed MP4s (~367MB total)
├── Shaders/                   # Metal shaders for UI effects
├── Utils/                     # HapticManager, PaletteManager, LazyView, etc.
└── Views/
    ├── Components/            # Reusable UI (DifficultyGauge, FilterChip, etc.)
    ├── Exercises/             # Library, detail, create
    ├── Programs/              # List, detail, phase/week/day detail, edit, import, activation
    ├── Workout/               # Active workout, exercise card, rest timer, summary
    ├── History/               # History list, workout detail, progress charts, PRs, edit sheet
    ├── Onboarding/            # 4-page first-run onboarding
    └── Profile/               # Profile, settings, help, theme, contribution graph
```
