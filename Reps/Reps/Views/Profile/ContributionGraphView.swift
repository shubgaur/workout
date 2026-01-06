import SwiftUI
import SwiftData

struct ContributionGraphView: View {
    let workouts: [WorkoutSession]

    private let weeks = Constants.ContributionGraph.weeksToShow
    private let days = 7

    private var workoutsByDate: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]

        for workout in workouts where workout.endTime != nil {
            let day = calendar.startOfDay(for: workout.startTime)
            counts[day, default: 0] += 1
        }

        return counts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("ACTIVITY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            // Day labels
            HStack(alignment: .top, spacing: RepsTheme.Spacing.sm) {
                // Day of week labels
                VStack(alignment: .trailing, spacing: 2) {
                    Text("").frame(height: 10) // Spacer for month labels
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                            .frame(width: 12, height: 10)
                    }
                }

                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Month labels
                        HStack(spacing: 2) {
                            ForEach(monthLabels, id: \.offset) { label in
                                Text(label.name)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundStyle(RepsTheme.Colors.textTertiary)
                                    .frame(width: CGFloat(label.width) * 12 + CGFloat(label.width - 1) * 2, alignment: .leading)
                            }
                        }
                        .frame(height: 10)

                        // Contribution grid
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(10), spacing: 2), count: 7), spacing: 2) {
                            ForEach(datesForGrid, id: \.self) { date in
                                ContributionCell(
                                    date: date,
                                    count: workoutsByDate[Calendar.current.startOfDay(for: date)] ?? 0
                                )
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: RepsTheme.Spacing.xs) {
                Text("Less")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textTertiary)

                ForEach(0..<5) { level in
                    Rectangle()
                        .fill(colorForLevel(level))
                        .frame(width: 10, height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                Text("More")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textTertiary)

                Spacer()

                Text("\(totalWorkouts) workouts")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    // MARK: - Computed Properties

    private var totalWorkouts: Int {
        workouts.filter { $0.endTime != nil }.count
    }

    private var datesForGrid: [Date] {
        let calendar = Calendar.current
        let today = Date()

        // Find the start of the current week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // Sunday = 1
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6 - daysToSubtract, to: today) else {
            return []
        }

        // Go back `weeks` weeks
        let totalDays = weeks * 7
        guard let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: endOfWeek) else {
            return []
        }

        return (0..<totalDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    private var monthLabels: [(name: String, width: Int, offset: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var labels: [(name: String, width: Int, offset: Int)] = []
        var currentMonth = -1
        var weekCount = 0
        var weekOffset = 0

        for (index, date) in datesForGrid.enumerated() {
            let month = calendar.component(.month, from: date)
            let dayOfWeek = calendar.component(.weekday, from: date)

            if dayOfWeek == 1 { // Sunday - start of new week column
                if month != currentMonth {
                    if currentMonth != -1 && weekCount > 0 {
                        labels.append((name: formatter.string(from: calendar.date(byAdding: .month, value: -1, to: date) ?? date), width: weekCount, offset: weekOffset))
                    }
                    currentMonth = month
                    weekOffset = index / 7
                    weekCount = 1
                } else {
                    weekCount += 1
                }
            }
        }

        // Add last month
        if weekCount > 0, let lastDate = datesForGrid.last {
            labels.append((name: formatter.string(from: lastDate), width: weekCount, offset: weekOffset))
        }

        return labels
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return RepsTheme.Colors.surfaceElevated
        case 1: return RepsTheme.Colors.accent.opacity(0.3)
        case 2: return RepsTheme.Colors.accent.opacity(0.5)
        case 3: return RepsTheme.Colors.accent.opacity(0.7)
        default: return RepsTheme.Colors.accent
        }
    }
}

// MARK: - Contribution Cell

struct ContributionCell: View {
    let date: Date
    let count: Int

    var body: some View {
        Rectangle()
            .fill(colorForCount)
            .frame(width: 10, height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private var colorForCount: Color {
        switch count {
        case 0: return RepsTheme.Colors.surfaceElevated
        case 1: return RepsTheme.Colors.accent.opacity(0.4)
        case 2: return RepsTheme.Colors.accent.opacity(0.6)
        case 3: return RepsTheme.Colors.accent.opacity(0.8)
        default: return RepsTheme.Colors.accent
        }
    }
}

#Preview {
    ContributionGraphView(workouts: [])
        .padding()
        .background(RepsTheme.Colors.background)
        .preferredColorScheme(.dark)
}
