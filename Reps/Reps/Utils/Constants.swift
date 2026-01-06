import Foundation

/// App-wide constants to avoid magic numbers
enum Constants {

    // MARK: - Rest Timer

    enum RestTimer {
        static let defaultSeconds = 90
        static let shortAdjustment = 15
        static let mediumAdjustment = 30

        /// Haptic warning thresholds (seconds remaining)
        enum HapticWarnings {
            static let medium = 10
            static let light = 5
            static let countdown = 3
        }
    }

    // MARK: - Workout Defaults

    enum Workout {
        static let defaultSets = 3
        static let defaultReps = 10
    }

    // MARK: - Contribution Graph

    enum ContributionGraph {
        static let weeksToShow = 17
    }

    // MARK: - Formulas

    enum Formulas {
        /// Epley formula constant for 1RM estimation: weight * (1 + reps / 30)
        static let epleyDivisor: Double = 30.0
    }

    // MARK: - Volume Display

    enum VolumeDisplay {
        static let millionThreshold = 1_000_000.0
        static let thousandThreshold = 1_000.0
    }

    // MARK: - Layout

    enum Layout {
        static let setColumnWidth: CGFloat = 50
        static let previousColumnWidth: CGFloat = 80
        static let checkButtonSize: CGFloat = 50
    }

    // MARK: - Time Constants

    enum Time {
        static let secondsPerHour = 3600
        static let secondsPerMinute = 60
    }
}

// MARK: - Array Extension

extension Array {
    /// Sort array by keyPath - consolidates common sorting pattern
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}
