import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Bindable var day: ProgramDay
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var showingAddExercise = false
    @State private var activeWorkoutSession: WorkoutSession?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                // Start Workout button (if workout exists)
                if day.dayType == .training, day.workoutTemplate != nil {
                    startWorkoutButton
                }

                // Day type selector
                dayTypeSection

                // Workout template
                if day.dayType == .training {
                    workoutSection
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
        .navigationTitle(day.name.isEmpty ? "Day \(day.dayNumber)" : day.name)
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigation()
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView(exercises: exercises) { selectedExercise in
                addExercise(selectedExercise)
            }
        }
        .fullScreenCover(item: $activeWorkoutSession) { session in
            ActiveWorkoutView(session: session) {
                activeWorkoutSession = nil
            }
        }
    }

    private var startWorkoutButton: some View {
        Button {
            startWorkout()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Workout")
                    .font(RepsTheme.Typography.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RepsButtonStyle(style: .primary))
    }

    private func startWorkout() {
        guard let template = day.workoutTemplate else { return }

        let session = WorkoutSession(template: template, programDay: day)
        // Set default name from program context
        if let week = day.week,
           let phase = week.phase,
           let program = phase.program {
            session.name = "\(program.name) · W\(week.weekNumber)D\(day.dayNumber)"
        }
        modelContext.insert(session)

        // Deep copy exercise groups from template into session
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

                for setTemplate in exercise.sortedSetTemplates {
                    let loggedSet = LoggedSet(
                        setNumber: setTemplate.setNumber,
                        setType: setTemplate.setType
                    )
                    if let targetTime = setTemplate.targetTime {
                        loggedSet.time = targetTime
                    }
                    if let targetReps = setTemplate.targetReps {
                        loggedSet.reps = targetReps
                    }
                    loggedSet.side = setTemplate.side
                    loggedSet.workoutExercise = sessionExercise
                    sessionExercise.loggedSets.append(loggedSet)
                }
                sessionGroup.exercises.append(sessionExercise)
            }
            session.exerciseGroups.append(sessionGroup)
        }

        activeWorkoutSession = session
    }

    private var dayTypeSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("DAY TYPE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(spacing: RepsTheme.Spacing.sm) {
                ForEach(DayType.allCases, id: \.self) { type in
                    DayTypeButton(
                        type: type,
                        isSelected: day.dayType == type,
                        action: { day.dayType = type }
                    )
                }
            }
        }
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                Button {
                    showingAddExercise = true
                } label: {
                    HStack(spacing: RepsTheme.Spacing.xxs) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            if let template = day.workoutTemplate {
                ForEach(template.sortedExerciseGroups) { group in
                    ExerciseGroupCard(group: group)
                }
            } else {
                emptyWorkoutState
            }
        }
    }

    private var emptyWorkoutState: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "dumbbell")
                .font(.system(size: 32))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No exercises added")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Button {
                showingAddExercise = true
            } label: {
                Label("Add Exercise", systemImage: "plus")
            }
            .buttonStyle(RepsButtonStyle(style: .secondary))
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.xl)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private func addExercise(_ exercise: Exercise) {
        // Create workout template if needed
        if day.workoutTemplate == nil {
            let template = WorkoutTemplate(name: day.name.isEmpty ? "Day \(day.dayNumber) Workout" : day.name)
            template.programDay = day
            day.workoutTemplate = template
            modelContext.insert(template)
        }

        guard let template = day.workoutTemplate else { return }

        // Create exercise group
        let group = ExerciseGroup(
            groupType: .single,
            order: template.exerciseGroups.count
        )
        group.workoutTemplate = template

        // Create workout exercise
        let workoutExercise = WorkoutExercise(order: 0)
        workoutExercise.exercise = exercise
        workoutExercise.exerciseGroup = group

        // Add 3 default sets
        for i in 1...3 {
            let setTemplate = SetTemplate(setNumber: i, setType: .working)
            setTemplate.workoutExercise = workoutExercise
            workoutExercise.setTemplates.append(setTemplate)
        }

        group.exercises.append(workoutExercise)
        template.exerciseGroups.append(group)
    }
}

// MARK: - Day Type Button

struct DayTypeButton: View {
    let type: DayType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: RepsTheme.Spacing.xxs) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(RepsTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RepsTheme.Spacing.sm)
            .background(isSelected ? RepsTheme.Colors.accent.opacity(0.2) : RepsTheme.Colors.surface)
            .foregroundStyle(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .stroke(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch type {
        case .training: return "dumbbell.fill"
        case .rest: return "moon.fill"
        case .activeRecovery: return "figure.walk"
        case .deload: return "arrow.down.circle"
        }
    }
}

// MARK: - Exercise Group Card

struct ExerciseGroupCard: View {
    let group: ExerciseGroup

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Group header (for supersets/circuits)
            if group.groupType != .single {
                HStack(spacing: RepsTheme.Spacing.xs) {
                    Image(systemName: groupIcon)
                        .foregroundStyle(RepsTheme.Colors.accent)
                    Text(group.groupType.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            // Exercises in group
            ForEach(group.sortedExercises) { workoutExercise in
                if let exercise = workoutExercise.exercise {
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        WorkoutExerciseRow(workoutExercise: workoutExercise)
                    }
                    .buttonStyle(.plain)
                } else {
                    WorkoutExerciseRow(workoutExercise: workoutExercise)
                }
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(group.groupType != .single ? RepsTheme.Colors.accent.opacity(0.3) : RepsTheme.Colors.border, lineWidth: 1)
        )
    }

    private var groupIcon: String {
        switch group.groupType {
        case .single: return "1.circle"
        case .superset: return "2.circle"
        case .triset: return "3.circle"
        case .circuit: return "arrow.3.trianglepath"
        case .zone: return "target"
        }
    }
}

// MARK: - Workout Exercise Row

struct WorkoutExerciseRow: View {
    let workoutExercise: WorkoutExercise

    private var setsSummary: String {
        let sets = workoutExercise.sortedSetTemplates
        guard !sets.isEmpty else { return "No sets" }

        let setCount = sets.count
        let firstSet = sets[0]

        var parts: [String] = []
        parts.append("\(setCount) set\(setCount == 1 ? "" : "s")")

        if let reps = firstSet.targetReps {
            parts.append("x \(reps) reps")
        } else if let time = firstSet.targetTime {
            let minutes = time / 60
            let seconds = time % 60
            if minutes > 0 {
                parts.append("x \(minutes):\(String(format: "%02d", seconds))")
            } else {
                parts.append("x \(seconds)s")
            }
        }

        if let notes = firstSet.notes, !notes.isEmpty {
            parts.append("· \(notes)")
        }

        return parts.joined(separator: " ")
    }

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            // Exercise image placeholder
            RoundedRectangle(cornerRadius: RepsTheme.Radius.xs)
                .fill(RepsTheme.Colors.surfaceElevated)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 16))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                )

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text(setsSummary)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                if let notes = workoutExercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        ExerciseCell(exercise: exercise)
                    }
                    .listRowBackground(RepsTheme.Colors.surface)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DayDetailView(day: ProgramDay(dayNumber: 1, name: "Full Body Strength", dayType: .training))
    }
    .modelContainer(for: Exercise.self, inMemory: true)
    .preferredColorScheme(.dark)
}
