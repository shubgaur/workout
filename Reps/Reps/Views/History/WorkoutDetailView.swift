import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Bindable var workout: WorkoutSession

    @Query private var allSettings: [UserSettings]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    private var weightLabel: String {
        allSettings.first?.weightUnit.displayName ?? "lbs"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.lg) {
                // Header stats
                statsHeader

                // Exercise breakdown
                exerciseBreakdown

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
        .navigationTitle(workout.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            WorkoutEditSheet(workout: workout)
        }
        .alert("Delete Workout?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(workout)
                dismiss()
            }
        } message: {
            Text("This will permanently delete this workout and all its data.")
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            // Date and rating
            HStack {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                    Text(formatDate(workout.startTime))
                        .font(RepsTheme.Typography.subheadline)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    if let endTime = workout.endTime {
                        Text("\(formatTime(workout.startTime)) - \(formatTime(endTime))")
                            .font(RepsTheme.Typography.caption)
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                if let difficulty = workout.rating {
                    DifficultyGauge(value: difficulty, size: 44)
                }
            }

            // Stats cards
            HStack(spacing: RepsTheme.Spacing.sm) {
                DetailStatCard(
                    icon: "clock.fill",
                    value: workout.formattedDuration,
                    label: "Duration"
                )

                DetailStatCard(
                    icon: "scalemass.fill",
                    value: "\(Int(workout.totalVolume))",
                    label: "Volume (\(weightLabel))"
                )

                DetailStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(workout.completedSets)",
                    label: "Sets"
                )

                DetailStatCard(
                    icon: "dumbbell.fill",
                    value: "\(workout.completedExercises)",
                    label: "Exercises"
                )
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            Text("EXERCISES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            ForEach(workout.sortedExerciseGroups) { group in
                ForEach(group.sortedExercises) { exercise in
                    ExerciseHistoryCard(exercise: exercise, weightLabel: weightLabel)
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("NOTES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Text(notes)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
                .padding(RepsTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        }
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(RepsTheme.Colors.accent)

            Text(value)
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RepsTheme.Spacing.sm)
        .background(RepsTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
    }
}

// MARK: - Exercise History Card

struct ExerciseHistoryCard: View {
    let exercise: WorkoutExercise
    var weightLabel: String = "lbs"

    // Flexible column detection
    private var hasTimeColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.time != nil }
    }

    private var hasWeightColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.weight != nil } ||
        !exercise.sortedLoggedSets.contains { $0.time != nil }
    }

    private var hasRepsColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.reps != nil } ||
        !exercise.sortedLoggedSets.contains { $0.time != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Exercise name
            HStack {
                Text(exercise.exercise?.name ?? "Unknown Exercise")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Spacer()

                // Best set indicator
                if let bestSet = bestCompletedSet {
                    HStack(spacing: RepsTheme.Spacing.xxs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(RepsTheme.Colors.warning)
                        Text(bestSetDisplay(bestSet))
                            .font(RepsTheme.Typography.mono)
                            .foregroundStyle(RepsTheme.Colors.accent)
                    }
                }
            }

            // Muscle groups
            if let muscles = exercise.exercise?.muscleGroups, !muscles.isEmpty {
                Text(muscles.map { $0.displayName }.joined(separator: ", "))
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Sets table
            VStack(spacing: 0) {
                // Header - flexible columns
                HStack(spacing: 0) {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    if hasTimeColumn {
                        Text("TIME")
                            .frame(maxWidth: .infinity)
                    }
                    if hasWeightColumn {
                        Text(weightLabel.uppercased())
                            .frame(maxWidth: .infinity)
                    }
                    if hasRepsColumn {
                        Text("REPS")
                            .frame(maxWidth: .infinity)
                    }
                    if hasWeightColumn && hasRepsColumn && !hasTimeColumn {
                        Text("1RM")
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
                .padding(.vertical, RepsTheme.Spacing.xs)

                Divider()
                    .background(RepsTheme.Colors.border)

                // Sets
                ForEach(exercise.sortedLoggedSets.filter { $0.isCompleted }) { set in
                    HStack(spacing: 0) {
                        Text("\(set.setNumber)")
                            .frame(width: 40, alignment: .leading)

                        if hasTimeColumn {
                            Text(set.time.map { formatTime($0) } ?? "-")
                                .frame(maxWidth: .infinity)
                        }

                        if hasWeightColumn {
                            Text(set.weight.map { "\(Int($0)) \(weightLabel)" } ?? "-")
                                .frame(maxWidth: .infinity)
                        }

                        if hasRepsColumn {
                            Text(set.reps.map { "\($0)" } ?? "-")
                                .frame(maxWidth: .infinity)
                        }

                        if hasWeightColumn && hasRepsColumn && !hasTimeColumn {
                            Text(estimated1RM(set).map { "\(Int($0))" } ?? "-")
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .padding(.vertical, RepsTheme.Spacing.xs)
                }
            }
            .padding(RepsTheme.Spacing.sm)
            .background(RepsTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))

            // Notes
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textTertiary)
                    .italic()
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private var bestCompletedSet: LoggedSet? {
        let completed = exercise.loggedSets.filter { $0.isCompleted }
        // For time-based: best = longest time; for weight-based: best = highest volume
        if hasTimeColumn && !hasWeightColumn {
            return completed.max { ($0.time ?? 0) < ($1.time ?? 0) }
        }
        return completed.max { ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }

    private func bestSetDisplay(_ set: LoggedSet) -> String {
        if let time = set.time, !hasWeightColumn {
            return formatTime(time)
        }
        if let weight = set.weight, let reps = set.reps {
            return "\(Int(weight))\(weightLabel) x \(reps)"
        }
        if let time = set.time {
            return formatTime(time)
        }
        return "-"
    }

    private func estimated1RM(_ set: LoggedSet) -> Double? {
        guard let weight = set.weight, let reps = set.reps, reps > 0 else { return nil }
        return weight * (1 + Double(reps) / 30)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins):\(String(format: "%02d", secs))"
        }
        return "\(secs)s"
    }
}
