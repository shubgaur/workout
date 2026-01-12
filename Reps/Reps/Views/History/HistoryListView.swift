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

    // Cached computed values for performance
    @State private var cachedWorkouts: [WorkoutSession] = []
    @State private var cachedGroupedWorkouts: [(key: String, value: [WorkoutSession])] = []

    private func refreshWorkouts() {
        cachedWorkouts = filterWorkouts()
        cachedGroupedWorkouts = groupWorkouts(cachedWorkouts)
    }

    private func filterWorkouts() -> [WorkoutSession] {
        switch selectedFilter {
        case .all:
            return allWorkouts.filter { $0.status == .completed || $0.wasSkipped }
        case .completed:
            return allWorkouts.filter { $0.status == .completed && !$0.wasSkipped }
        case .skipped:
            return allWorkouts.filter { $0.wasSkipped }
        }
    }

    private func groupWorkouts(_ workouts: [WorkoutSession]) -> [(key: String, value: [WorkoutSession])] {
        let grouped = Dictionary(grouping: workouts) { workout in
            formatDateHeader(workout.startTime)
        }
        return grouped.sorted { $0.value.first?.startTime ?? Date() > $1.value.first?.startTime ?? Date() }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterRow
                    .padding(.vertical, RepsTheme.Spacing.sm)

                Group {
                    if cachedWorkouts.isEmpty {
                        emptyState
                    } else {
                        workoutList
                    }
                }
            }
            .transparentNavigation()
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    GradientTitle(text: "History")
                    Spacer()
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.top, RepsTheme.Spacing.xl)
                .padding(.bottom, RepsTheme.Spacing.sm)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                refreshWorkouts()
            }
            .onChange(of: allWorkouts.count) { _, _ in
                refreshWorkouts()
            }
            .onChange(of: selectedFilter) { _, _ in
                refreshWorkouts()
            }
        }
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    ADFilterChip(
                        label: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(RepsTheme.Animations.segment) {
                            selectedFilter = filter
                        }
                        HapticManager.filterSelected()
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in }
        )
    }

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(RepsTheme.Colors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RepsTheme.Colors.accent.opacity(0.5))
            }

            Text("No Workout History")
                .font(RepsTheme.Typography.title)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Complete a workout to see it here")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: RepsTheme.Spacing.sm) {
                ForEach(cachedGroupedWorkouts, id: \.key) { group in
                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                        // Section header
                        Text(group.key)
                            .font(RepsTheme.Typography.label)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                            .padding(.horizontal, RepsTheme.Spacing.xs)
                            .padding(.top, RepsTheme.Spacing.md)

                        // Workout cards
                        VStack(spacing: RepsTheme.Spacing.xs) {
                            ForEach(group.value) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutHistoryCell(workout: workout)
                                }
                                .buttonStyle(ScalingPressButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.bottom, RepsTheme.Spacing.tabBarSafeArea)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "THIS WEEK"
        } else {
            return Self.monthYearFormatter.string(from: date).uppercased()
        }
    }
}

// MARK: - Workout History Cell

struct WorkoutHistoryCell: View {
    let workout: WorkoutSession

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                        HStack(spacing: RepsTheme.Spacing.xs) {
                            Text(workout.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(RepsTheme.Colors.text)

                            if workout.wasSkipped {
                                Text("SKIPPED")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(RepsTheme.Colors.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(RepsTheme.Colors.accent.opacity(0.15))
                                    )
                            }
                        }

                        Text(formatDate(workout.startTime))
                            .font(.system(size: 12))
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
                    StatPill(icon: "scalemass", value: "\(Int(workout.totalVolume)) lbs")
                    StatPill(icon: "checkmark.circle", value: "\(workout.completedSets) sets")
                }

                // Exercises preview
                if !workout.exerciseGroups.isEmpty {
                    Text(exerciseNames)
                        .font(.system(size: 12))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }

    private var exerciseNames: String {
        workout.sortedExerciseGroups
            .flatMap { $0.sortedExercises }
            .compactMap { $0.exercise?.name }
            .prefix(3)
            .joined(separator: ", ")
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.detailDateFormatter.string(from: date)
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
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
    }
}
