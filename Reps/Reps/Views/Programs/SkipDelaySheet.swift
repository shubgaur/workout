import SwiftUI
import SwiftData

/// Sheet for skipping or delaying a workout
struct SkipDelaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let program: Program

    @State private var selectedOption: SkipOption = .skipOnly

    private var currentWorkoutName: String {
        program.currentDay?.workoutTemplate?.name ?? "this workout"
    }

    private var nextWorkoutName: String {
        // Peek at next workout
        let currentDayIndex = program.currentDayIndex

        guard let week = program.currentWeek else { return "next workout" }
        let days = week.sortedDays.filter { $0.dayType == .training }

        if currentDayIndex + 1 < days.count {
            return days[currentDayIndex + 1].workoutTemplate?.name ?? "next workout"
        }
        return "next workout"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: RepsTheme.Spacing.lg) {
                // Header
                VStack(spacing: RepsTheme.Spacing.xs) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.system(size: 48))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    Text("Skip \(currentWorkoutName)?")
                        .font(RepsTheme.Typography.title3)
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .padding(.top, RepsTheme.Spacing.lg)

                // Options
                VStack(spacing: RepsTheme.Spacing.sm) {
                    SkipOptionRow(
                        option: .skipOnly,
                        isSelected: selectedOption == .skipOnly,
                        subtitle: "Continue with \(nextWorkoutName) next"
                    )
                    .onTapGesture { selectedOption = .skipOnly }

                    SkipOptionRow(
                        option: .pushSchedule,
                        isSelected: selectedOption == .pushSchedule,
                        subtitle: "\(currentWorkoutName) moves to next scheduled day"
                    )
                    .onTapGesture { selectedOption = .pushSchedule }
                }
                .padding(.horizontal)

                Spacer()

                // Action buttons
                HStack(spacing: RepsTheme.Spacing.md) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(RepsButtonStyle(style: .secondary))

                    Button("Confirm") {
                        performSkip()
                    }
                    .buttonStyle(RepsButtonStyle(style: .primary))
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
    }

    private func performSkip() {
        switch selectedOption {
        case .skipOnly:
            ScheduleService.skipWorkout(program, in: modelContext)
        case .pushSchedule:
            ScheduleService.skipWorkout(program, in: modelContext)
        }
        dismiss()
    }
}

// MARK: - Skip Option

enum SkipOption {
    case skipOnly
    case pushSchedule

    var title: String {
        switch self {
        case .skipOnly:
            return "Skip this workout only"
        case .pushSchedule:
            return "Push entire schedule back"
        }
    }

    var icon: String {
        switch self {
        case .skipOnly:
            return "forward.fill"
        case .pushSchedule:
            return "calendar.badge.clock"
        }
    }
}

// MARK: - Skip Option Row

private struct SkipOptionRow: View {
    let option: SkipOption
    let isSelected: Bool
    let subtitle: String

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                .foregroundStyle(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)

            Image(systemName: option.icon)
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(RepsTheme.Typography.subheadline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text(subtitle)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(RepsTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .fill(isSelected ? RepsTheme.Colors.accent.opacity(0.1) : RepsTheme.Colors.surfaceElevated)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            SkipDelaySheet(program: Program(name: "Push Pull Legs"))
        }
}
