import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endTime != nil }) private var completedWorkouts: [WorkoutSession]
    @Query private var personalRecords: [PersonalRecord]
    @State private var selectedTimeRange: ProfileTimeRange = .month

    // Cached computed values for performance
    @State private var cachedTotalVolume: Double = 0
    @State private var cachedStreak: Int = 0
    @State private var cachedWorkoutPercentChange: Double?
    @State private var cachedVolumePercentChange: Double?
    @State private var cachedVolumeData: [ChartDataPoint] = []
    @State private var cachedPreviousData: [ChartDataPoint]?
    @State private var needsRefresh = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RepsTheme.Spacing.xl) {
                    // 2x2 Stats Grid
                    statsGrid

                    // Volume Progress Chart
                    volumeChartSection

                    // Activity Graph
                    ContributionGraphView(workouts: completedWorkouts)

                    // Quick Links
                    menuSection
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.top, RepsTheme.Spacing.sm)
                .padding(.bottom, 70)
            }
            .transparentNavigation()
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .safeAreaInset(edge: .top) {
                // Custom gradient title
                HStack {
                    GradientTitle(text: "Profile")
                    Spacer()
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.top, RepsTheme.Spacing.xl)
                .padding(.bottom, RepsTheme.Spacing.sm)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                refreshCachedStats()
            }
            .onChange(of: completedWorkouts.count) { _, _ in
                refreshCachedStats()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                refreshVolumeData()
            }
        }
    }

    // MARK: - Cache Refresh

    private func refreshCachedStats() {
        cachedTotalVolume = completedWorkouts.reduce(0) { $0 + $1.totalVolume }
        cachedStreak = computeStreak()
        cachedWorkoutPercentChange = computeWorkoutPercentChange()
        cachedVolumePercentChange = computeVolumePercentChange()
        refreshVolumeData()
    }

    private func refreshVolumeData() {
        cachedVolumeData = generateVolumeData(for: selectedTimeRange)
        cachedPreviousData = generatePreviousPeriodVolumeData(for: selectedTimeRange)
    }

    private func computeStreak() -> Int {
        guard !completedWorkouts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let workoutDates = Set(completedWorkouts.compactMap { workout -> Date? in
            guard let endTime = workout.endTime else { return nil }
            return calendar.startOfDay(for: endTime)
        }).sorted(by: >)

        guard let lastWorkout = workoutDates.first else { return 0 }

        let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkout, to: today).day ?? 0
        if daysSinceLastWorkout > 1 { return 0 }

        var streak = 1
        var previousDate = lastWorkout

        for date in workoutDates.dropFirst() {
            let daysDiff = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
            if daysDiff == 1 {
                streak += 1
                previousDate = date
            } else if daysDiff > 1 {
                break
            }
        }

        return streak
    }

    private func computeWorkoutPercentChange() -> Double? {
        let thisMonth = workoutsInPeriod(days: 30)
        let lastMonth = workoutsInPeriod(days: 60) - thisMonth
        guard lastMonth > 0 else { return nil }
        return Double(thisMonth - lastMonth) / Double(lastMonth) * 100
    }

    private func computeVolumePercentChange() -> Double? {
        let thisMonth = volumeInPeriod(days: 30)
        let lastMonth = volumeInPeriod(days: 60) - thisMonth
        guard lastMonth > 0 else { return nil }
        return (thisMonth - lastMonth) / lastMonth * 100
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("OVERVIEW")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .padding(.leading, RepsTheme.Spacing.xs)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
                GridItem(.flexible(), spacing: RepsTheme.Spacing.sm)
            ], spacing: RepsTheme.Spacing.sm) {
                // Total Workouts
                StatMetricCard(
                    value: "\(completedWorkouts.count)",
                    unit: "",
                    label: "Workouts",
                    percentChange: cachedWorkoutPercentChange
                )

                // Personal Records - tappable
                NavigationLink {
                    PRHistoryTimelineView()
                } label: {
                    StatMetricCard(
                        value: "\(personalRecords.count)",
                        unit: "",
                        label: "Personal Records",
                        percentChange: nil,
                        showChevron: true
                    )
                }
                .buttonStyle(ScalingPressButtonStyle())

                // Total Volume - tappable
                NavigationLink {
                    VolumeBreakdownView()
                } label: {
                    StatMetricCard(
                        value: formatVolume(cachedTotalVolume),
                        unit: "lbs",
                        label: "Total Volume",
                        percentChange: cachedVolumePercentChange,
                        showChevron: true
                    )
                }
                .buttonStyle(ScalingPressButtonStyle())

                // Current Streak
                StatMetricCard(
                    value: "\(cachedStreak)",
                    unit: "days",
                    label: "Current Streak",
                    percentChange: nil
                )
            }
        }
    }

    // MARK: - Volume Chart Section

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            HStack {
                Text("VOLUME PROGRESS")
                    .font(RepsTheme.Typography.label)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                // Time range picker
                Menu {
                    ForEach(ProfileTimeRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(RepsTheme.Animations.segment) {
                                selectedTimeRange = range
                            }
                            HapticManager.filterSelected()
                        } label: {
                            Text(range.rawValue)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimeRange.rawValue)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.xs)

            // Chart - no external height constraint, let it size naturally
            CumulativeProgressChart(
                currentPeriodData: cachedVolumeData,
                previousPeriodData: cachedPreviousData,
                height: 180,
                xAxisLabelFormatter: xAxisFormatter(for: selectedTimeRange)
            )
            .padding(RepsTheme.Spacing.md)
            .repsCard()
        }
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: RepsTheme.Spacing.xs) {
            NavigationLink {
                PersonalRecordsView()
            } label: {
                MenuRow(
                    icon: "trophy.fill",
                    title: "All Personal Records",
                    iconColor: RepsTheme.Colors.warning
                )
            }
            .buttonStyle(ScalingPressButtonStyle())

            NavigationLink {
                SettingsView()
            } label: {
                MenuRow(
                    icon: "gearshape.fill",
                    title: "Settings",
                    iconColor: RepsTheme.Colors.textSecondary
                )
            }
            .buttonStyle(ScalingPressButtonStyle())
        }
    }

    // MARK: - Helper Methods

    private func xAxisFormatter(for range: ProfileTimeRange) -> ((Int) -> String)? {
        switch range {
        case .week:
            return nil  // Default numeric labels work fine for 0-6
        case .month:
            return nil  // Default numeric labels work fine for 0-29
        case .quarter:
            // Show week numbers for 90-day view (12 weekly data points)
            return { index in "W\(index + 1)" }
        case .year:
            // Show month abbreviations for 1-year view (12 monthly data points)
            let monthAbbreviations = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            return { index in
                // Calculate which month this index represents (starting from 12 months ago)
                let monthIndex = (currentMonth - 12 + index) % 12
                let adjustedIndex = monthIndex < 0 ? monthIndex + 12 : monthIndex
                return monthAbbreviations[adjustedIndex]
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1f", volume / 1_000_000) + "M"
        } else if volume >= 1000 {
            return String(format: "%.0f", volume / 1000) + "K"
        }
        return "\(Int(volume))"
    }

    private func workoutsInPeriod(days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return completedWorkouts.filter { ($0.endTime ?? Date.distantPast) >= cutoff }.count
    }

    private func volumeInPeriod(days: Int) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return completedWorkouts
            .filter { ($0.endTime ?? Date.distantPast) >= cutoff }
            .reduce(0) { $0 + $1.totalVolume }
    }

    private func generateVolumeData(for range: ProfileTimeRange) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [Double] = []

        let numberOfPoints: Int = range.dataPoints
        let interval: Int = range.intervalDays

        for i in 0..<numberOfPoints {
            let dayOffset: Int = -(i * interval)
            let endDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            let startDate = calendar.date(byAdding: .day, value: -interval, to: endDate) ?? endDate

            let volume = completedWorkouts
                .filter { workout in
                    guard let endTime = workout.endTime else { return false }
                    return endTime >= startDate && endTime < endDate
                }
                .reduce(0) { $0 + $1.totalVolume }

            dataPoints.insert(volume, at: 0)
        }

        // Convert to cumulative ChartDataPoints
        var cumulative: [ChartDataPoint] = []
        var total = 0.0
        for (index, point) in dataPoints.enumerated() {
            total += point
            cumulative.append(ChartDataPoint(index: index, value: total))
        }

        return cumulative
    }

    private func generatePreviousPeriodVolumeData(for range: ProfileTimeRange) -> [ChartDataPoint]? {
        let calendar = Calendar.current
        let periodDays: Int = range.totalDays
        let offsetDate = calendar.date(byAdding: .day, value: -periodDays, to: Date()) ?? Date()

        var dataPoints: [Double] = []
        let numberOfPoints: Int = range.dataPoints
        let interval: Int = range.intervalDays

        for i in 0..<numberOfPoints {
            let dayOffset: Int = -(i * interval)
            let endDate = calendar.date(byAdding: .day, value: dayOffset, to: offsetDate) ?? offsetDate
            let startDate = calendar.date(byAdding: .day, value: -interval, to: endDate) ?? endDate

            let volume = completedWorkouts
                .filter { workout in
                    guard let endTime = workout.endTime else { return false }
                    return endTime >= startDate && endTime < endDate
                }
                .reduce(0) { $0 + $1.totalVolume }

            dataPoints.insert(volume, at: 0)
        }

        // Convert to cumulative ChartDataPoints
        var cumulative: [ChartDataPoint] = []
        var total = 0.0
        for (index, point) in dataPoints.enumerated() {
            total += point
            cumulative.append(ChartDataPoint(index: index, value: total))
        }

        // Only return if there's data
        return (cumulative.last?.value ?? 0) > 0 ? cumulative : nil
    }
}

// MARK: - Profile Time Range

enum ProfileTimeRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case year = "1 Year"

    var dataPoints: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 12  // Weekly for quarter
        case .year: 12     // Monthly for year
        }
    }

    var intervalDays: Int {
        switch self {
        case .week: 1
        case .month: 1
        case .quarter: 7
        case .year: 30
        }
    }

    var totalDays: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        }
    }
}

// MARK: - Menu Row

private struct MenuRow: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .padding(RepsTheme.Spacing.md)
        .repsCard()
    }
}

