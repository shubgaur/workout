import SwiftUI
import SwiftData

struct PhaseDetailView: View {
    @Bindable var phase: Phase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                // Header
                if let description = phase.phaseDescription, !description.isEmpty {
                    Text(description)
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(RepsTheme.Spacing.md)
                        .background(RepsTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                }

                // Weeks
                if phase.sortedWeeks.isEmpty {
                    emptyWeeksState
                } else {
                    weeksSection
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
        .background(RepsTheme.Colors.background)
        .navigationTitle(phase.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addWeek()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
    }

    private var weeksSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("WEEKS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .padding(.leading, RepsTheme.Spacing.xs)

            ForEach(phase.sortedWeeks) { week in
                NavigationLink(destination: WeekDetailView(week: week)) {
                    WeekRow(week: week)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyWeeksState: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No weeks yet")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Button("Add Week") {
                addWeek()
            }
            .font(RepsTheme.Typography.caption)
            .foregroundStyle(RepsTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.xl)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private func addWeek() {
        let week = Week(weekNumber: phase.weeks.count + 1)
        week.phase = phase
        phase.weeks.append(week)
    }
}

// MARK: - Week Row

struct WeekRow: View {
    let week: Week

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Week number badge
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(RepsTheme.Colors.surfaceElevated)
                    .frame(width: 48, height: 48)

                VStack(spacing: 0) {
                    Text("WK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                    Text("\(week.weekNumber)")
                        .font(RepsTheme.Typography.mono)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text("Week \(week.weekNumber)")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                let workoutDays = week.days.filter { $0.workoutTemplate != nil }.count
                let restDays = week.days.filter { $0.dayType == .rest }.count
                Text("\(workoutDays) workout\(workoutDays == 1 ? "" : "s") • \(restDays) rest day\(restDays == 1 ? "" : "s")")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                if let notes = week.notes, !notes.isEmpty {
                    Text(notes)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PhaseDetailView(phase: Phase(name: "Phase 1: Foundation", order: 0))
    }
    .preferredColorScheme(.dark)
}
