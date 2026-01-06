import SwiftUI
import SwiftData

/// Sheet for activating a program with week/day selection and schedule picker
struct ProgramActivationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let program: Program

    @State private var selectedWeekIndex: Int = 0
    @State private var selectedDayIndex: Int = 0
    @State private var scheduledDays: [Int] = [1, 3, 5]  // Default: Mon, Wed, Fri

    private var sortedPhases: [Phase] {
        program.sortedPhases
    }

    private var currentPhase: Phase? {
        sortedPhases.first
    }

    private var weeksInPhase: [Week] {
        currentPhase?.sortedWeeks ?? []
    }

    private var daysInSelectedWeek: [ProgramDay] {
        guard selectedWeekIndex < weeksInPhase.count else { return [] }
        return weeksInPhase[selectedWeekIndex].sortedDays.filter { $0.dayType == .training }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Week Selector
                    weekSection

                    // Day Selector
                    if !daysInSelectedWeek.isEmpty {
                        daySection
                    }

                    // Schedule Picker
                    scheduleSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Start \(program.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        activateProgram()
                    }
                    .fontWeight(.semibold)
                    .disabled(scheduledDays.isEmpty)
                }
            }
        }
    }

    // MARK: - Week Section

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which week to begin?")
                .font(.headline)

            WeekPicker(
                totalWeeks: weeksInPhase.count,
                selectedWeek: $selectedWeekIndex
            )
            .onChange(of: selectedWeekIndex) { _, _ in
                selectedDayIndex = 0
            }
        }
    }

    // MARK: - Day Section

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Starting workout:")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Array(daysInSelectedWeek.enumerated()), id: \.element.id) { index, day in
                    DayRow(
                        dayNumber: index + 1,
                        workoutName: day.workoutTemplate?.name ?? "Rest Day",
                        isSelected: selectedDayIndex == index
                    )
                    .onTapGesture {
                        selectedDayIndex = index
                    }
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training days:")
                .font(.headline)

            DayOfWeekPicker(selectedDays: $scheduledDays)

            if scheduledDays.isEmpty {
                Text("Select at least one training day")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text(ScheduleService.formatScheduledDays(scheduledDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func activateProgram() {
        ScheduleService.activateProgram(
            program,
            atPhase: 0,
            week: selectedWeekIndex,
            day: selectedDayIndex,
            scheduledDays: scheduledDays
        )
        dismiss()
    }
}

// MARK: - Day Row

private struct DayRow: View {
    let dayNumber: Int
    let workoutName: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            Text("Day \(dayNumber): \(workoutName)")
                .font(.subheadline)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            ProgramActivationSheet(program: Program(name: "Push Pull Legs"))
        }
}
