import SwiftUI
import SwiftData
import Charts

struct ProgressChartView: View {
    let exercise: Exercise
    @Query private var workouts: [WorkoutSession]

    @State private var selectedMetric: ProgressMetric = .maxWeight
    @State private var selectedTimeRange: TimeRange = .month

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            // Metric picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(ProgressMetric.allCases, id: \.self) { metric in
                    Text(metric.displayName).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            // Time range picker
            Picker("Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)

            // Chart
            if chartData.isEmpty {
                emptyChartState
            } else {
                chart
            }

            // Stats summary
            statsSummary
        }
        .padding(RepsTheme.Spacing.md)
    }

    private var emptyChartState: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("Not enough data")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Text("Complete more workouts with this exercise to see your progress")
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }

    private var chart: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value(selectedMetric.displayName, dataPoint.value)
            )
            .foregroundStyle(RepsTheme.Colors.accent)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value(selectedMetric.displayName, dataPoint.value)
            )
            .foregroundStyle(RepsTheme.Colors.accent)
            .symbolSize(60)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(RepsTheme.Colors.border)
                AxisValueLabel()
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .frame(height: 200)
    }

    private var statsSummary: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            ProgressStatCard(
                label: "Current",
                value: currentValue,
                trend: nil
            )

            ProgressStatCard(
                label: "Best",
                value: bestValue,
                trend: nil
            )

            ProgressStatCard(
                label: "Progress",
                value: progressValue,
                trend: progressTrend
            )
        }
    }

    // MARK: - Data Processing

    private var chartData: [ProgressDataPoint] {
        let cutoffDate = selectedTimeRange.cutoffDate

        let relevantWorkouts = workouts
            .filter { $0.status == .completed && $0.startTime >= cutoffDate }
            .sorted { $0.startTime < $1.startTime }

        return relevantWorkouts.compactMap { workout -> ProgressDataPoint? in
            let exerciseSets = workout.sortedExerciseGroups
                .flatMap { $0.sortedExercises }
                .filter { $0.exercise?.id == exercise.id }
                .flatMap { $0.loggedSets }
                .filter { $0.isCompleted }

            guard !exerciseSets.isEmpty else { return nil }

            let value: Double
            switch selectedMetric {
            case .maxWeight:
                value = exerciseSets.compactMap { $0.weight }.max() ?? 0
            case .estimated1RM:
                value = exerciseSets.compactMap { set -> Double? in
                    guard let weight = set.weight, let reps = set.reps, reps > 0 else { return nil }
                    return weight * (1 + Double(reps) / 30)
                }.max() ?? 0
            case .totalVolume:
                value = exerciseSets.reduce(0) { total, set in
                    let weight = set.weight ?? 0
                    let reps = Double(set.reps ?? 0)
                    return total + (weight * reps)
                }
            case .maxReps:
                value = Double(exerciseSets.compactMap { $0.reps }.max() ?? 0)
            }

            return value > 0 ? ProgressDataPoint(date: workout.startTime, value: value) : nil
        }
    }

    private var currentValue: String {
        guard let last = chartData.last else { return "-" }
        return formatValue(last.value)
    }

    private var bestValue: String {
        guard let best = chartData.max(by: { $0.value < $1.value }) else { return "-" }
        return formatValue(best.value)
    }

    private var progressValue: String {
        guard chartData.count >= 2 else { return "-" }
        let first = chartData.first!.value
        let last = chartData.last!.value
        let percentage = ((last - first) / first) * 100
        return String(format: "%.1f%%", percentage)
    }

    private var progressTrend: ProgressTrend? {
        guard chartData.count >= 2 else { return nil }
        let first = chartData.first!.value
        let last = chartData.last!.value
        if last > first {
            return .up
        } else if last < first {
            return .down
        }
        return .neutral
    }

    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .maxWeight, .estimated1RM:
            return "\(Int(value)) kg"
        case .totalVolume:
            return "\(Int(value)) kg"
        case .maxReps:
            return "\(Int(value))"
        }
    }
}

// MARK: - Supporting Types

struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum ProgressMetric: CaseIterable {
    case maxWeight
    case estimated1RM
    case totalVolume
    case maxReps

    var displayName: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .estimated1RM: return "Est. 1RM"
        case .totalVolume: return "Volume"
        case .maxReps: return "Max Reps"
        }
    }
}

enum TimeRange: CaseIterable {
    case week
    case month
    case threeMonths
    case year

    var displayName: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .year: return "1Y"
        }
    }

    var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }
    }
}

enum ProgressTrend {
    case up, down, neutral
}

// MARK: - Progress Stat Card

struct ProgressStatCard: View {
    let label: String
    let value: String
    let trend: ProgressTrend?

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            HStack(spacing: RepsTheme.Spacing.xxs) {
                Text(value)
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                if let trend = trend {
                    Image(systemName: trendIcon(trend))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(trendColor(trend))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.sm)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
    }

    private func trendIcon(_ trend: ProgressTrend) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    private func trendColor(_ trend: ProgressTrend) -> Color {
        switch trend {
        case .up: return RepsTheme.Colors.success
        case .down: return RepsTheme.Colors.error
        case .neutral: return RepsTheme.Colors.textSecondary
        }
    }
}
