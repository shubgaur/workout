import Foundation

/// Centralized time formatting utility to avoid duplication across the codebase
enum TimeFormatter {

    /// Format for elapsed workout time display (e.g., "1:45:30" or "45:30")
    static func formatElapsed(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Format for elapsed workout time (TimeInterval version)
    static func formatElapsed(_ interval: TimeInterval) -> String {
        formatElapsed(Int(interval))
    }

    /// Format for rest timer display (e.g., "1:30")
    static func formatRestTimer(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Format for workout duration summary (e.g., "1h 45m" or "45m 30s")
    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }

    /// Format for workout duration summary (TimeInterval version)
    static func formatDuration(_ interval: TimeInterval) -> String {
        formatDuration(Int(interval))
    }
}
