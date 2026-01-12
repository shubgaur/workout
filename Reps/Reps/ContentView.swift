import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var scrubProgress: CGFloat? = nil
    @State private var activeWorkoutSession: WorkoutSession?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Root gradient background - single source of truth
            MetalGradientView(
                palette: PaletteManager.shared.activePalette,
                speed: 0.3,
                brightness: 0.5
            )
            .ignoresSafeArea()

            // Tab content with custom switching
            tabContent
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab, scrubProgress: $scrubProgress)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $activeWorkoutSession) { session in
            ActiveWorkoutView(session: session) {
                activeWorkoutSession = nil
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(onStartWorkout: startWorkout)
        case .programs:
            LazyView(ProgramListView())
        case .exercises:
            LazyView(ExerciseLibraryView())
        case .history:
            LazyView(HistoryListView())
        case .profile:
            LazyView(ProfileView())
        }
    }

    private func startWorkout(template: WorkoutTemplate?, programDay: ProgramDay?) {
        let session = WorkoutSession(template: template, programDay: programDay)
        modelContext.insert(session)

        // Copy exercise groups from template if available
        if let template = template {
            for group in template.sortedExerciseGroups {
                let sessionGroup = ExerciseGroup(
                    groupType: group.groupType,
                    order: group.order,
                    name: group.name,
                    notes: group.notes
                )
                sessionGroup.workoutSession = session

                for exercise in group.sortedExercises {
                    let sessionExercise = WorkoutExercise(
                        order: exercise.order,
                        isOptional: exercise.isOptional,
                        notes: exercise.notes,
                        restSeconds: exercise.restSeconds
                    )
                    sessionExercise.exercise = exercise.exercise
                    sessionExercise.exerciseGroup = sessionGroup

                    // Create logged sets from templates
                    for setTemplate in exercise.sortedSetTemplates {
                        let loggedSet = LoggedSet(
                            setNumber: setTemplate.setNumber,
                            setType: setTemplate.setType
                        )
                        // TODO: Populate previousReps/previousWeight from history
                        loggedSet.workoutExercise = sessionExercise
                        sessionExercise.loggedSets.append(loggedSet)
                    }

                    sessionGroup.exercises.append(sessionExercise)
                }

                session.exerciseGroups.append(sessionGroup)
            }
        }

        activeWorkoutSession = session
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case home, programs, exercises, history, profile
}

// MARK: - Placeholder Views

struct HomeView: View {
    var onStartWorkout: (WorkoutTemplate?, ProgramDay?) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.lg) {
                // Quick Start Card
                QuickStartCard {
                    onStartWorkout(nil, nil)
                }

                // Today's Workout
                TodayWorkoutCard(onStartWorkout: onStartWorkout)

                // Recent Workouts (placeholder)
                RecentWorkoutsSection()
            }
            .padding(RepsTheme.Spacing.md)
            .padding(.bottom, RepsTheme.Spacing.tabBarSafeArea)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .safeAreaInset(edge: .top) {
            // Title header
            HStack {
                Text("Reps")
                    .font(RepsTheme.Typography.largeTitle)
                    .foregroundStyle(RepsTheme.Colors.text)
                Spacer()
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.md)
            .padding(.bottom, RepsTheme.Spacing.sm)
        }
    }
}

struct QuickStartCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
                    Text("Quick Start")
                        .font(RepsTheme.Typography.headline)
                        .foregroundColor(RepsTheme.Colors.text)
                    Text("Start an empty workout")
                        .font(RepsTheme.Typography.subheadline)
                        .foregroundColor(RepsTheme.Colors.textSecondary)
                }

                Spacer()

                // Liquid metal + button
                LiquidMetalIconButton(icon: "plus", action: {
                    onTap()
                }, size: 44)
            }
            .padding(RepsTheme.Spacing.md)
            .repsCard()
        }
        .buttonStyle(.plain)
    }
}

struct TodayWorkoutCard: View {
    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query private var userStats: [UserStats]

    var onStartWorkout: ((WorkoutTemplate?, ProgramDay?) -> Void)?

    private var activeProgram: Program? { activePrograms.first }
    private var stats: UserStats? { userStats.first }

    var body: some View {
        if let program = activeProgram {
            if program.isPaused {
                PausedProgramCard(program: program)
            } else if ScheduleService.isScheduledToday(program) {
                ScheduledWorkoutCard(program: program, stats: stats, onStartWorkout: onStartWorkout)
            } else {
                NextWorkoutCard(program: program)
            }
        } else {
            NoProgramCard()
        }
    }
}

// MARK: - Scheduled Workout Card

struct ScheduledWorkoutCard: View {
    let program: Program
    let stats: UserStats?
    var onStartWorkout: ((WorkoutTemplate?, ProgramDay?) -> Void)?

    @State private var showSkipSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            // Header with streak
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Workout")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    Text(program.name)
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)
                }

                Spacer()

                if let streak = stats?.currentStreak, streak > 0 {
                    StreakBadge(streak: streak, isFrozen: stats?.streakFrozen ?? false)
                }
            }

            // Current workout info
            if let day = program.currentDay, let template = day.workoutTemplate {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.progressDescription)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)

                    Text(template.name)
                        .font(RepsTheme.Typography.title3)
                        .foregroundStyle(RepsTheme.Colors.text)

                    HStack(spacing: RepsTheme.Spacing.md) {
                        Label("\(template.exerciseGroups.flatMap { $0.exercises }.count) exercises", systemImage: "dumbbell")
                        if let duration = template.estimatedDuration {
                            Label("\(duration) min", systemImage: "clock")
                        }
                    }
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }

            // Action buttons
            HStack(spacing: RepsTheme.Spacing.sm) {
                Button {
                    if let day = program.currentDay {
                        onStartWorkout?(day.workoutTemplate, day)
                    }
                } label: {
                    Text("Start Workout")
                        .font(RepsTheme.Typography.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RepsButtonStyle(style: .primary))

                Menu {
                    Button {
                        showSkipSheet = true
                    } label: {
                        Label("Skip Today", systemImage: "forward.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(RepsTheme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                }
            }
        }
        .padding(RepsTheme.Spacing.md)
        .repsCard()
        .sheet(isPresented: $showSkipSheet) {
            SkipDelaySheet(program: program)
        }
    }
}

// MARK: - Next Workout Card

struct NextWorkoutCard: View {
    let program: Program
    var onStartEarly: ((WorkoutTemplate?, ProgramDay?) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            HStack {
                Text("Rest Day")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Spacer()

                if let nextDate = program.nextScheduledDate {
                    Text(nextDate, format: .dateTime.weekday(.wide))
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            if let day = program.currentDay, let template = day.workoutTemplate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next: \(template.name)")
                        .font(RepsTheme.Typography.subheadline)
                        .foregroundStyle(RepsTheme.Colors.text)

                    Text(program.progressDescription)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }

            Button {
                if let day = program.currentDay {
                    onStartEarly?(day.workoutTemplate, day)
                }
            } label: {
                Text("Start Early")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidMetalButtonStyle())
        }
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }
}

// MARK: - Paused Program Card

struct PausedProgramCard: View {
    let program: Program
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(program.name)
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)

                    if let until = program.pausedUntil {
                        Text("Paused until \(until, format: .dateTime.month().day())")
                            .font(RepsTheme.Typography.caption)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: RepsTheme.Spacing.sm) {
                Button {
                    resumeProgram()
                } label: {
                    Text("Resume Now")
                        .font(RepsTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RepsButtonStyle(style: .primary))

                Button {
                    // Extend pause - would show date picker
                } label: {
                    Text("Extend")
                        .font(RepsTheme.Typography.subheadline)
                }
                .buttonStyle(RepsButtonStyle(style: .secondary))
            }
        }
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }

    private func resumeProgram() {
        ScheduleService.resumeProgram(program)

        // Unfreeze streak
        let descriptor = FetchDescriptor<UserStats>()
        if let stats = try? modelContext.fetch(descriptor).first {
            stats.unfreezeStreak()
        }
    }
}

// MARK: - No Program Card

struct NoProgramCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("Today's Workout")
                .font(RepsTheme.Typography.headline)
                .foregroundColor(RepsTheme.Colors.text)

            Text("No program active. Start a program to see your scheduled workouts here.")
                .font(RepsTheme.Typography.body)
                .foregroundColor(RepsTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }
}

struct RecentWorkoutsSection: View {
    static let completedStatus = WorkoutStatus.completed.rawValue

    @Query(sort: \WorkoutSession.startTime, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    private var recentWorkouts: [WorkoutSession] {
        allWorkouts.filter { $0.status == .completed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("Recent Workouts")
                .font(RepsTheme.Typography.headline)
                .foregroundColor(RepsTheme.Colors.text)

            if recentWorkouts.isEmpty {
                Text("Complete your first workout to see it here")
                    .font(RepsTheme.Typography.body)
                    .foregroundColor(RepsTheme.Colors.textSecondary)
            } else {
                ForEach(recentWorkouts.prefix(5)) { session in
                    NavigationLink {
                        WorkoutDetailView(workout: session)
                    } label: {
                        RecentWorkoutRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }
}

struct RecentWorkoutRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(RepsTheme.Typography.subheadline)
                    .foregroundColor(RepsTheme.Colors.text)
                Text("\(session.startTime, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day()) · \(session.totalExercises) exercises · \(session.formattedDuration)")
                    .font(RepsTheme.Typography.caption)
                    .foregroundColor(RepsTheme.Colors.textSecondary)
            }
            Spacer()
            if let difficulty = session.rating {
                DifficultyGaugeCompact(value: difficulty)
            }
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                EmptyStateView(
                    icon: "clock.fill",
                    title: "No History",
                    message: "Complete a workout to see your history"
                )
                .padding(RepsTheme.Spacing.md)
                .padding(.bottom, RepsTheme.Spacing.tabBarSafeArea)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("History")
        }
    }
}

// ProfileView and SettingsView are in Views/Profile/
// EmptyStateView is in Views/Components/EmptyStateView.swift

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, Program.self, Phase.self, Week.self, ProgramDay.self,
            WorkoutTemplate.self, ExerciseGroup.self, WorkoutExercise.self,
            SetTemplate.self, WorkoutSession.self, LoggedSet.self,
            PersonalRecord.self, UserSettings.self
        ], inMemory: true)
}
