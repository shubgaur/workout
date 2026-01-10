import SwiftUI
import SwiftData

struct WeekDetailView: View {
    @Bindable var week: Week
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                // Header with notes
                if let notes = week.notes, !notes.isEmpty {
                    notesCard(notes)
                }

                // Days grid
                daysSection
            }
            .padding(RepsTheme.Spacing.md)
        }
        .navigationTitle("Week \(week.weekNumber)")
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigation()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addDay()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                Image(systemName: "note.text")
                    .foregroundStyle(RepsTheme.Colors.accent)
                Text("NOTES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Text(notes)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("DAYS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .padding(.leading, RepsTheme.Spacing.xs)

            if week.sortedDays.isEmpty {
                emptyDaysState
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RepsTheme.Spacing.sm) {
                    ForEach(week.sortedDays) { day in
                        NavigationLink(destination: DayDetailView(day: day)) {
                            DayCard(day: day)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyDaysState: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No days configured")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Button("Add Day") {
                addDay()
            }
            .font(RepsTheme.Typography.caption)
            .foregroundStyle(RepsTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.xl)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private func addDay() {
        let dayNumber = week.days.count + 1
        let day = ProgramDay(
            dayNumber: dayNumber,
            name: "Day \(dayNumber)",
            dayType: .training
        )
        day.week = week
        week.days.append(day)
    }
}

// MARK: - Day Card

struct DayCard: View {
    let day: ProgramDay

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Day header
            HStack {
                Text("DAY \(day.dayNumber)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                dayTypeIndicator
            }

            // Day name or type
            Text(day.name.isEmpty ? day.dayType.displayName : day.name)
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)
                .lineLimit(2)

            Spacer()

            // Workout info
            if let workout = day.workoutTemplate {
                HStack(spacing: RepsTheme.Spacing.xs) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                    Text("\(workout.exerciseGroups.count) exercises")
                        .font(RepsTheme.Typography.caption)
                }
                .foregroundStyle(RepsTheme.Colors.textSecondary)
            } else if day.dayType == .rest {
                HStack(spacing: RepsTheme.Spacing.xs) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                    Text("Rest Day")
                        .font(RepsTheme.Typography.caption)
                }
                .foregroundStyle(RepsTheme.Colors.textTertiary)
            }
        }
        .padding(RepsTheme.Spacing.md)
        .frame(height: 120)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var dayTypeIndicator: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 8, height: 8)
    }

    private var indicatorColor: Color {
        switch day.dayType {
        case .training:
            return RepsTheme.Colors.accent
        case .rest:
            return RepsTheme.Colors.textTertiary
        case .activeRecovery:
            return RepsTheme.Colors.success
        case .deload:
            return RepsTheme.Colors.warning
        }
    }

    private var backgroundColor: Color {
        day.dayType == .rest ? RepsTheme.Colors.surfaceElevated : RepsTheme.Colors.surface
    }

    private var borderColor: Color {
        day.workoutTemplate != nil ? RepsTheme.Colors.accent.opacity(0.3) : RepsTheme.Colors.border
    }
}

#Preview {
    NavigationStack {
        WeekDetailView(week: Week(weekNumber: 1))
    }
    .preferredColorScheme(.dark)
}
