import Foundation
import SwiftData

// MARK: - Pause Resume Mode

enum PauseResumeMode: String, Codable, CaseIterable {
    case continueWhereLeft
    case restartCurrentWeek
    case goBackOneWeek
}

// MARK: - Program Model

@Model
final class Program {
    @Attribute(.unique) var id: UUID
    var name: String
    var programDescription: String?
    var programDetails: String?
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool

    // Scheduling
    var scheduledDays: [Int] = []  // 0=Sun, 1=Mon, ... 6=Sat
    var startDate: Date?           // When user activated/started program
    var pausedUntil: Date?         // nil = not paused, Date = return date
    var pauseResumeMode: PauseResumeMode?

    // Progress tracking
    var currentPhaseIndex: Int = 0
    var currentWeekIndex: Int = 0
    var currentDayIndex: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Phase.program)
    var phases: [Phase] = []

    init(
        id: UUID = UUID(),
        name: String,
        programDescription: String? = nil,
        programDetails: String? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.programDescription = programDescription
        self.programDetails = programDetails
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = isActive
    }

    // MARK: - Computed Properties

    var isPaused: Bool {
        guard let pausedUntil else { return false }
        return pausedUntil > Date()
    }

    var currentPhase: Phase? {
        let sorted = sortedPhases
        guard currentPhaseIndex >= 0 && currentPhaseIndex < sorted.count else { return nil }
        return sorted[currentPhaseIndex]
    }

    var currentWeek: Week? {
        guard let phase = currentPhase else { return nil }
        let weeks = phase.sortedWeeks
        guard currentWeekIndex >= 0 && currentWeekIndex < weeks.count else { return nil }
        return weeks[currentWeekIndex]
    }

    var currentDay: ProgramDay? {
        guard let week = currentWeek else { return nil }
        let days = week.sortedDays
        guard currentDayIndex >= 0 && currentDayIndex < days.count else { return nil }
        return days[currentDayIndex]
    }

    var currentWorkoutTemplate: WorkoutTemplate? {
        currentDay?.workoutTemplate
    }

    /// Returns next scheduled date based on scheduledDays (empty = every day)
    var nextScheduledDate: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard !scheduledDays.isEmpty else {
            return today // Empty = daily, so today is always scheduled
        }
        let currentWeekday = calendar.component(.weekday, from: today) - 1 // 0=Sun

        // Find next scheduled day
        for offset in 0..<7 {
            let checkDay = (currentWeekday + offset) % 7
            if scheduledDays.contains(checkDay) {
                if offset == 0 {
                    return today // Today is a scheduled day
                }
                return calendar.date(byAdding: .day, value: offset, to: today)
            }
        }
        return nil
    }

    /// Check if today is a scheduled training day (empty = every day)
    var isScheduledToday: Bool {
        guard !scheduledDays.isEmpty else { return true }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1 // 0=Sun
        return scheduledDays.contains(weekday)
    }

    /// Overall progress as percentage (0.0 - 1.0)
    var progress: Double {
        let total = totalWorkouts
        guard total > 0 else { return 0 }
        let completed = completedWorkoutsCount
        return Double(completed) / Double(total)
    }

    var completedWorkoutsCount: Int {
        // Count workouts before current position
        var count = 0
        let sorted = sortedPhases

        for (phaseIdx, phase) in sorted.enumerated() {
            let weeks = phase.sortedWeeks
            for (weekIdx, week) in weeks.enumerated() {
                let days = week.sortedDays.filter { $0.dayType == .training }
                for (dayIdx, _) in days.enumerated() {
                    if phaseIdx < currentPhaseIndex ||
                       (phaseIdx == currentPhaseIndex && weekIdx < currentWeekIndex) ||
                       (phaseIdx == currentPhaseIndex && weekIdx == currentWeekIndex && dayIdx < currentDayIndex) {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    /// Human-readable progress string including phase name
    var progressDescription: String {
        let sorted = sortedPhases
        if currentPhaseIndex >= 0 && currentPhaseIndex < sorted.count {
            let phaseName = sorted[currentPhaseIndex].name
                .replacingOccurrences(of: #"Phase \d+:\s*"#, with: "", options: .regularExpression)
            return "\(phaseName) · Week \(currentWeekIndex + 1), Day \(currentDayIndex + 1)"
        }
        return "Week \(currentWeekIndex + 1), Day \(currentDayIndex + 1)"
    }

    var sortedPhases: [Phase] {
        phases.sorted { $0.order < $1.order }
    }

    var totalWeeks: Int {
        phases.reduce(0) { $0 + $1.weeks.count }
    }

    var totalWorkouts: Int {
        phases.flatMap { $0.weeks }
            .flatMap { $0.days }
            .filter { $0.dayType == .training }
            .count
    }
}
