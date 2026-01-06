import Foundation
import SwiftData

@Model
final class UserStats {
    @Attribute(.unique) var id: UUID
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWorkoutDate: Date?
    var streakFrozen: Bool = false  // Vacation mode preserves streak

    init(id: UUID = UUID()) {
        self.id = id
    }

    // MARK: - Streak Management

    /// Call when completing a workout
    func recordWorkout(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastWorkoutDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 && !streakFrozen {
                // Missed days without freeze
                currentStreak = 1
            }
            // daysDiff == 0 means same day, don't change streak
        } else {
            // First workout
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastWorkoutDate = date
        streakFrozen = false
    }

    /// Call when entering vacation/pause mode
    func freezeStreak() {
        streakFrozen = true
    }

    /// Call when resuming from vacation
    func unfreezeStreak() {
        streakFrozen = false
    }

    /// Check if streak is broken (call daily)
    func checkStreakStatus(scheduledDays: [Int]) {
        guard !streakFrozen else { return }
        guard let lastDate = lastWorkoutDate else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)

        // Get yesterday
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        let yesterdayWeekday = calendar.component(.weekday, from: yesterday) - 1 // 0=Sun

        // If yesterday was scheduled and we didn't work out, break streak
        if scheduledDays.contains(yesterdayWeekday) && lastDay < yesterday {
            currentStreak = 0
        }
    }
}
