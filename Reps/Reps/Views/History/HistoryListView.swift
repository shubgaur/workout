import SwiftUI
import SwiftData

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case completed = "Completed"
    case skipped = "Skipped"
}

struct HistoryListView: View {
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var allWorkouts: [WorkoutSession]
    @State private var selectedFilter: HistoryFilter = .all

    private var workouts: [WorkoutSession] {
        switch selectedFilter {
        case .all:
            return allWorkouts.filter { $0.status == .completed || $0.wasSkipped }
        case .completed:
            return allWorkouts.filter { $0.status == .completed && !$0.wasSkipped }
        case .skipped:
            return allWorkouts.filter { $0.wasSkipped }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.vertical, RepsTheme.Spacing.sm)

                Group {
                    if workouts.isEmpty {
                        emptyState
                    } else {
                        workoutList
                    }
                }
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("History")
        }
    }

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "clock.fill")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No Workout History")
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Complete a workout to see it here")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: RepsTheme.Spacing.md) {
                ForEach(groupedWorkouts, id: \.key) { group in
                    Section {
                        ForEach(group.value) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout)
                            } label: {
                                WorkoutHistoryCell(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack {
                            Text(group.key)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(RepsTheme.Colors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, RepsTheme.Spacing.md)
                        .padding(.top, RepsTheme.Spacing.md)
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.bottom, RepsTheme.Spacing.xl)
        }
    }

    private var groupedWorkouts: [(key: String, value: [WorkoutSession])] {
        let grouped = Dictionary(grouping: workouts) { workout in
            formatDateHeader(workout.startTime)
        }
        return grouped.sorted { $0.value.first?.startTime ?? Date() > $1.value.first?.startTime ?? Date() }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "THIS WEEK"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date).uppercased()
        }
    }
}

// MARK: - Workout History Cell

struct WorkoutHistoryCell: View {
    let workout: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                    HStack(spacing: RepsTheme.Spacing.xs) {
                        Text(workout.displayName)
                            .font(RepsTheme.Typography.headline)
                            .foregroundStyle(RepsTheme.Colors.text)

                        if workout.wasSkipped {
                            Text("SKIPPED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.orange.opacity(0.2))
                                )
                        }
                    }

                    Text(formatDate(workout.startTime))
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }

                Spacer()

                // Difficulty (only show for completed workouts)
                if !workout.wasSkipped, let difficulty = workout.rating {
                    DifficultyGaugeCompact(value: difficulty)
                }
            }

            // Stats row
            HStack(spacing: RepsTheme.Spacing.lg) {
                StatPill(icon: "clock", value: workout.formattedDuration)
                StatPill(icon: "flame", value: "\(Int(workout.totalVolume)) kg")
                StatPill(icon: "checkmark.circle", value: "\(workout.completedSets) sets")
            }

            // Exercises preview
            if !workout.exerciseGroups.isEmpty {
                Text(exerciseNames)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private var exerciseNames: String {
        workout.sortedExerciseGroups
            .flatMap { $0.sortedExercises }
            .compactMap { $0.exercise?.name }
            .prefix(3)
            .joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(RepsTheme.Colors.accent)

            Text(value)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
    }
}
