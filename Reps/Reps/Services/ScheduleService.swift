import Foundation
import SwiftData

/// Handles program scheduling, skip/delay logic, and progress advancement
struct ScheduleService {

    // MARK: - Schedule Queries

    /// Check if today is a scheduled training day (empty scheduledDays = every day)
    static func isScheduledToday(_ program: Program) -> Bool {
        guard !program.scheduledDays.isEmpty else { return true }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1 // 0=Sun
        return program.scheduledDays.contains(weekday)
    }

    /// Get next scheduled training date (empty scheduledDays = tomorrow)
    static func nextScheduledDate(_ program: Program) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard !program.scheduledDays.isEmpty else {
            return calendar.date(byAdding: .day, value: 1, to: today)
        }
        let currentWeekday = calendar.component(.weekday, from: today) - 1

        for offset in 1..<8 {
            let checkDay = (currentWeekday + offset) % 7
            if program.scheduledDays.contains(checkDay) {
                return calendar.date(byAdding: .day, value: offset, to: today)
            }
        }
        return nil
    }

    // MARK: - Program Activation

    /// Activate program at specific position
    static func activateProgram(
        _ program: Program,
        atPhase phaseIndex: Int = 0,
        week weekIndex: Int = 0,
        day dayIndex: Int = 0,
        scheduledDays: [Int]
    ) {
        program.isActive = true
        program.startDate = Date()
        program.currentPhaseIndex = phaseIndex
        program.currentWeekIndex = weekIndex
        program.currentDayIndex = dayIndex
        program.scheduledDays = scheduledDays
        program.pausedUntil = nil
        program.pauseResumeMode = nil
        program.updatedAt = Date()
    }

    /// Deactivate program
    static func deactivateProgram(_ program: Program) {
        program.isActive = false
        program.pausedUntil = nil
        program.pauseResumeMode = nil
        program.updatedAt = Date()
    }

    // MARK: - Progress Advancement

    /// Advance to next workout day in program
    static func advanceToNextDay(_ program: Program) {
        guard let currentPhase = program.currentPhase else { return }
        let weeks = currentPhase.sortedWeeks

        guard program.currentWeekIndex < weeks.count else { return }
        let currentWeek = weeks[program.currentWeekIndex]
        let days = currentWeek.sortedDays.filter { $0.dayType == .training }

        // Try next day in current week
        if program.currentDayIndex + 1 < days.count {
            program.currentDayIndex += 1
            program.updatedAt = Date()
            return
        }

        // Try next week in current phase
        if program.currentWeekIndex + 1 < weeks.count {
            program.currentWeekIndex += 1
            program.currentDayIndex = 0
            program.updatedAt = Date()
            return
        }

        // Try next phase
        let phases = program.sortedPhases
        if program.currentPhaseIndex + 1 < phases.count {
            program.currentPhaseIndex += 1
            program.currentWeekIndex = 0
            program.currentDayIndex = 0
            program.updatedAt = Date()
            return
        }

        // Program complete - keep at last position
    }

    // MARK: - Skip/Delay

    /// Skip current workout and advance to next
    static func skipWorkout(_ program: Program, in context: ModelContext) {
        guard let currentDay = program.currentDay else { return }

        // Create a skipped session for history
        let skippedSession = WorkoutSession(programDay: currentDay)
        skippedSession.wasSkipped = true
        skippedSession.status = .cancelled
        skippedSession.endTime = Date()
        context.insert(skippedSession)

        // Advance to next day
        advanceToNextDay(program)
    }

    // MARK: - Pause/Resume

    /// Pause program until specified date
    static func pauseProgram(
        _ program: Program,
        until date: Date,
        resumeMode: PauseResumeMode
    ) {
        program.pausedUntil = date
        program.pauseResumeMode = resumeMode
        program.updatedAt = Date()
    }

    /// Resume program immediately
    static func resumeProgram(_ program: Program) {
        guard let resumeMode = program.pauseResumeMode else {
            program.pausedUntil = nil
            program.updatedAt = Date()
            return
        }

        switch resumeMode {
        case .continueWhereLeft:
            // No change to position
            break

        case .restartCurrentWeek:
            program.currentDayIndex = 0

        case .goBackOneWeek:
            if program.currentWeekIndex > 0 {
                program.currentWeekIndex -= 1
                program.currentDayIndex = 0
            } else if program.currentPhaseIndex > 0 {
                // Go to last week of previous phase
                program.currentPhaseIndex -= 1
                if let phase = program.currentPhase {
                    program.currentWeekIndex = max(0, phase.weeks.count - 1)
                }
                program.currentDayIndex = 0
            }
        }

        program.pausedUntil = nil
        program.pauseResumeMode = nil
        program.updatedAt = Date()
    }

    /// Extend pause to new date
    static func extendPause(_ program: Program, until newDate: Date) {
        program.pausedUntil = newDate
        program.updatedAt = Date()
    }

    // MARK: - Workout Completion

    /// Mark current workout as completed and advance
    static func completeWorkout(_ program: Program, session: WorkoutSession) {
        session.programDay = program.currentDay
        advanceToNextDay(program)
    }

    // MARK: - Helpers

    /// Format scheduled days as readable string (e.g., "Mon, Wed, Fri")
    static func formatScheduledDays(_ days: [Int]) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().map { dayNames[$0] }.joined(separator: ", ")
    }

    /// Get day abbreviation for picker
    static func dayAbbreviation(_ dayIndex: Int) -> String {
        let abbrev = ["S", "M", "T", "W", "T", "F", "S"]
        guard dayIndex >= 0 && dayIndex < 7 else { return "" }
        return abbrev[dayIndex]
    }

    /// Get full day name
    static func dayName(_ dayIndex: Int) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard dayIndex >= 0 && dayIndex < 7 else { return "" }
        return names[dayIndex]
    }
}
