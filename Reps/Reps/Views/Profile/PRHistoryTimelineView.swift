import SwiftUI
import SwiftData

/// Displays personal records in a vertical timeline with scroll-tracking ruler
struct PRHistoryTimelineView: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse)
    private var allRecords: [PersonalRecord]

    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var scrollOffset: CGFloat = 0
    @State private var currentMonthIndex: Int = 0

    private let twelveMonthsAgo: Date = {
        Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
    }()

    // Filter to last 12 months and by muscle group
    private var filteredRecords: [PersonalRecord] {
        allRecords.filter { record in
            // Date filter: last 12 months
            guard record.achievedAt >= twelveMonthsAgo else { return false }

            // Muscle group filter
            if let muscle = selectedMuscleGroup {
                return record.exercise?.muscleGroups.contains(muscle) ?? false
            }
            return true
        }
    }

    // Group records by date
    private var groupedRecords: [(date: Date, records: [PersonalRecord])] {
        let calendar = Calendar.current
        var groups: [Date: [PersonalRecord]] = [:]

        for record in filteredRecords {
            let day = calendar.startOfDay(for: record.achievedAt)
            groups[day, default: []].append(record)
        }

        return groups
            .map { (date: $0.key, records: $0.value) }
            .sorted { $0.date > $1.date }
    }

    // Calculate month markers for the ruler
    private var monthMarkers: [MonthMarker] {
        let calendar = Calendar.current
        var markers: [MonthMarker] = []
        var currentMonth = -1
        var currentYear = -1
        var recordCountForMonth = 0

        for (index, group) in groupedRecords.enumerated() {
            let month = calendar.component(.month, from: group.date)
            let year = calendar.component(.year, from: group.date)

            if month != currentMonth || year != currentYear {
                if currentMonth != -1 {
                    // Estimate height based on record count (rough estimate)
                    let height = CGFloat(recordCountForMonth) * 100
                    markers.append(MonthMarker(
                        month: currentMonth,
                        year: currentYear,
                        height: max(height, 60),
                        recordCount: recordCountForMonth
                    ))
                }
                currentMonth = month
                currentYear = year
                recordCountForMonth = group.records.count
            } else {
                recordCountForMonth += group.records.count
            }

            // Last group
            if index == groupedRecords.count - 1 {
                let height = CGFloat(recordCountForMonth) * 100
                markers.append(MonthMarker(
                    month: currentMonth,
                    year: currentYear,
                    height: max(height, 60),
                    recordCount: recordCountForMonth
                ))
            }
        }

        return markers
    }

    var body: some View {
        Group {
            if filteredRecords.isEmpty {
                emptyState
            } else {
                timelineContent
            }
        }
        .navigationTitle("PR History")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.warning.opacity(0.5))

            Text("No Records Yet")
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            if selectedMuscleGroup != nil {
                Text("No PRs found for this muscle group in the last 12 months")
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Clear Filter") {
                    selectedMuscleGroup = nil
                }
                .font(RepsTheme.Typography.footnote)
                .foregroundStyle(RepsTheme.Colors.accent)
            } else {
                Text("Complete workouts to set PRs")
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Filter chips
            filterSection

            // Timeline
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    // Timeline ruler
                    TimelineRuler(
                        months: monthMarkers,
                        currentMonthIndex: currentMonthIndex,
                        totalHeight: CGFloat(groupedRecords.count) * 100
                    )

                    // Cards with connectors
                    LazyVStack(spacing: RepsTheme.Spacing.md) {
                        ForEach(Array(groupedRecords.enumerated()), id: \.element.date) { index, group in
                            HStack(alignment: .top, spacing: RepsTheme.Spacing.xs) {
                                // Connector line
                                TimelineConnector(
                                    isFirst: index == 0,
                                    isLast: index == groupedRecords.count - 1
                                )

                                // PR Card
                                PRTimelineCard(
                                    records: group.records,
                                    date: group.date
                                )
                            }
                        }
                    }
                    .padding(.trailing, RepsTheme.Spacing.md)
                }
                .padding(.top, RepsTheme.Spacing.md)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                FilterChip(
                    title: "All Muscles",
                    isSelected: selectedMuscleGroup == nil
                ) {
                    selectedMuscleGroup = nil
                }

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    FilterChip(
                        title: muscle.displayName,
                        isSelected: selectedMuscleGroup == muscle
                    ) {
                        selectedMuscleGroup = selectedMuscleGroup == muscle ? nil : muscle
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
        }
        // Capture horizontal drags to prevent tab swipe interference
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in }
        )
        .padding(.vertical, RepsTheme.Spacing.sm)
        .background(RepsTheme.Colors.surfaceElevated)
    }
}

#Preview {
    NavigationStack {
        PRHistoryTimelineView()
    }
    .modelContainer(for: PersonalRecord.self, inMemory: true)
    .preferredColorScheme(.dark)
}
