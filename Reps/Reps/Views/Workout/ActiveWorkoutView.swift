import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    var onDismiss: () -> Void

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var activeRestTimer: RestTimerState?
    @State private var showingSummary = false
    @State private var isSelectingForSuperset = false
    @State private var selectedGroupsForSuperset: Set<UUID> = []

    private var settings: UserSettings? {
        allSettings.first
    }

    private var canCreateSuperset: Bool {
        selectedGroupsForSuperset.count >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RepsTheme.Spacing.md) {
                    // Editable workout name
                    TextField("Name your workout", text: Binding(
                        get: { session.name ?? "" },
                        set: { session.name = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(RepsTheme.Colors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RepsTheme.Spacing.lg)
                    .padding(.top, RepsTheme.Spacing.sm)

                    // Rest timer overlay (if active)
                    if let restTimer = activeRestTimer {
                        RestTimerView(state: restTimer) {
                            activeRestTimer = nil
                        }
                        .padding(.horizontal, RepsTheme.Spacing.md)
                    }

                    // Superset selection banner
                    if isSelectingForSuperset {
                        SupersetSelectionBanner(
                            selectedCount: selectedGroupsForSuperset.count,
                            canCreate: canCreateSuperset,
                            onCancel: {
                                isSelectingForSuperset = false
                                selectedGroupsForSuperset.removeAll()
                            },
                            onCreate: createSuperset
                        )
                        .padding(.horizontal, RepsTheme.Spacing.md)
                    }

                    // Exercise groups
                    ForEach(session.sortedExerciseGroups) { group in
                        ActiveExerciseGroupCard(
                            group: group,
                            isSelecting: isSelectingForSuperset,
                            isSelected: selectedGroupsForSuperset.contains(group.id),
                            onSetCompleted: handleSetCompleted,
                            onToggleSelection: {
                                toggleGroupSelection(group)
                            },
                            onLongPress: {
                                if !isSelectingForSuperset && group.groupType == .single {
                                    isSelectingForSuperset = true
                                    selectedGroupsForSuperset.insert(group.id)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                        )
                    }

                    // Add exercise button
                    Button {
                        showingExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RepsButtonStyle(style: .secondary))
                    .padding(.horizontal, RepsTheme.Spacing.md)
                    .padding(.bottom, RepsTheme.Spacing.xl)
                }
                .padding(.top, RepsTheme.Spacing.md)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingCancelConfirmation = true
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .principal) {
                    WorkoutTimerDisplay(elapsedTime: elapsedTime)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { exercise in
                addExercise(exercise)
            }
        }
        .alert("Finish Workout?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Finish") {
                finishWorkout()
            }
        } message: {
            Text("You completed \(completedSetsCount) sets.")
        }
        .alert("Cancel Workout?", isPresented: $showingCancelConfirmation) {
            Button("Keep Going", role: .cancel) {}
            Button("Discard", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Your progress will be lost.")
        }
        .fullScreenCover(isPresented: $showingSummary) {
            WorkoutSummaryView(session: session) {
                onDismiss()
            }
        }
    }

    // MARK: - Computed Properties

    private var completedSetsCount: Int {
        session.exerciseGroups
            .flatMap { $0.exercises }
            .flatMap { $0.loggedSets }
            .filter { $0.isCompleted }
            .count
    }

    // MARK: - Timer

    private func startTimer() {
        elapsedTime = Date().timeIntervalSince(session.startTime)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(session.startTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions

    private func handleSetCompleted(set: LoggedSet, exercise: WorkoutExercise) {
        // Start rest timer
        let restSeconds = exercise.restSeconds ?? Constants.RestTimer.defaultSeconds
        activeRestTimer = RestTimerState(totalSeconds: restSeconds)

        // TODO: Check for PR
    }

    private func addExercise(_ exercise: Exercise) {
        let group = ExerciseGroup(
            groupType: .single,
            order: session.exerciseGroups.count
        )
        group.workoutSession = session

        let defaultRest = settings?.defaultRestSeconds ?? 90
        let workoutExercise = WorkoutExercise(
            order: 0,
            restSeconds: defaultRest
        )
        workoutExercise.exercise = exercise
        workoutExercise.exerciseGroup = group

        // Add default sets from settings
        let setsCount = settings?.defaultSets ?? 3
        for i in 1...setsCount {
            let set = LoggedSet(setNumber: i)
            set.workoutExercise = workoutExercise
            workoutExercise.loggedSets.append(set)
        }

        group.exercises.append(workoutExercise)
        session.exerciseGroups.append(group)
    }

    private func finishWorkout() {
        session.finish()
        showingSummary = true
    }

    private func cancelWorkout() {
        session.cancel()
        modelContext.delete(session)
        onDismiss()
    }

    private func toggleGroupSelection(_ group: ExerciseGroup) {
        if selectedGroupsForSuperset.contains(group.id) {
            selectedGroupsForSuperset.remove(group.id)
        } else if group.groupType == .single {
            selectedGroupsForSuperset.insert(group.id)
        }
    }

    private func createSuperset() {
        guard canCreateSuperset else { return }

        // Get selected groups sorted by order
        let selectedGroups = session.sortedExerciseGroups.filter { selectedGroupsForSuperset.contains($0.id) }
        guard selectedGroups.count >= 2 else { return }

        // Create new superset group
        let supersetGroup = ExerciseGroup(
            groupType: selectedGroups.count == 2 ? .superset : .triset,
            order: selectedGroups.first!.order
        )
        supersetGroup.workoutSession = session

        // Move exercises from selected groups to superset
        var exerciseOrder = 0
        for oldGroup in selectedGroups {
            for exercise in oldGroup.sortedExercises {
                exercise.order = exerciseOrder
                exercise.exerciseGroup = supersetGroup
                supersetGroup.exercises.append(exercise)
                exerciseOrder += 1
            }
            // Remove old group
            session.exerciseGroups.removeAll { $0.id == oldGroup.id }
            modelContext.delete(oldGroup)
        }

        session.exerciseGroups.append(supersetGroup)

        // Reorder remaining groups
        for (index, group) in session.sortedExerciseGroups.enumerated() {
            group.order = index
        }

        // Reset selection state
        isSelectingForSuperset = false
        selectedGroupsForSuperset.removeAll()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Workout Timer Display

struct WorkoutTimerDisplay: View {
    let elapsedTime: TimeInterval

    var body: some View {
        Text(TimeFormatter.formatElapsed(elapsedTime))
            .font(RepsTheme.Typography.mono)
            .foregroundStyle(RepsTheme.Colors.text)
    }
}

// MARK: - Superset Selection Banner

struct SupersetSelectionBanner: View {
    let selectedCount: Int
    let canCreate: Bool
    var onCancel: () -> Void
    var onCreate: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Create Superset")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)
                Text("\(selectedCount) exercises selected")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Spacer()

            Button("Cancel") {
                onCancel()
            }
            .font(RepsTheme.Typography.body)
            .foregroundStyle(RepsTheme.Colors.textSecondary)

            Button {
                onCreate()
            } label: {
                Text("Create")
                    .font(RepsTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(canCreate ? RepsTheme.Colors.background : RepsTheme.Colors.textTertiary)
                    .padding(.horizontal, RepsTheme.Spacing.md)
                    .padding(.vertical, RepsTheme.Spacing.sm)
                    .background(canCreate ? RepsTheme.Colors.accent : RepsTheme.Colors.surfaceElevated)
                    .clipShape(Capsule())
            }
            .disabled(!canCreate)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.accent, lineWidth: 2)
        )
    }
}

// MARK: - Active Exercise Group Card

struct ActiveExerciseGroupCard: View {
    @Bindable var group: ExerciseGroup
    var isSelecting: Bool = false
    var isSelected: Bool = false
    var onSetCompleted: (LoggedSet, WorkoutExercise) -> Void
    var onToggleSelection: (() -> Void)?
    var onLongPress: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Group header (for supersets)
            if group.groupType != .single && group.exercises.count > 1 {
                HStack {
                    Image(systemName: groupIcon)
                        .foregroundStyle(RepsTheme.Colors.accent)
                    Text(group.groupType.displayName)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.vertical, RepsTheme.Spacing.sm)
            }

            // Exercise cards
            ForEach(group.sortedExercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    onSetCompleted: { loggedSet in
                        onSetCompleted(loggedSet, exercise)
                    }
                )
            }
        }
        .overlay(
            Group {
                if isSelecting && group.groupType == .single {
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                        .stroke(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.border, lineWidth: isSelected ? 3 : 1)
                        .padding(.horizontal, RepsTheme.Spacing.md)
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                onToggleSelection?()
            }
        }
        .onLongPressGesture {
            onLongPress?()
        }
    }

    private var groupIcon: String {
        switch group.groupType {
        case .superset: return "arrow.triangle.2.circlepath"
        case .triset: return "arrow.3.trianglepath"
        case .circuit: return "arrow.clockwise"
        case .zone: return "timer"
        case .single: return "circle"
        }
    }
}

// MARK: - Rest Timer State

struct RestTimerState: Identifiable {
    let id = UUID()
    let totalSeconds: Int
    var startedAt = Date()

    var remainingSeconds: Int {
        max(0, totalSeconds - Int(Date().timeIntervalSince(startedAt)))
    }

    var isComplete: Bool {
        remainingSeconds <= 0
    }
}
