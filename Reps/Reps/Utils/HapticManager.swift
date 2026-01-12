import UIKit

/// Centralized haptic feedback manager with AnyDistance-inspired patterns.
/// Provides both raw haptics and semantic actions for weightlifting context.
enum HapticManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Raw Haptics

    /// Light impact - for subtle feedback (filter chips, toggles)
    static func light() {
        lightGenerator.impactOccurred()
    }

    /// Medium impact - for moderate feedback (button presses)
    static func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy impact - for strong feedback (major actions)
    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Rigid impact - sharp, crisp feedback (confirmations)
    static func rigid() {
        rigidGenerator.impactOccurred()
    }

    /// Soft impact - gentle, cushioned feedback (transitions)
    static func soft() {
        softGenerator.impactOccurred()
    }

    /// Selection feedback - for tab changes, picker selections
    static func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Success notification - for completed actions
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification - for alerts
    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification - for failures
    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Semantic Actions (Weightlifting Context)

    /// Tab bar selection changed
    static func tabChanged() {
        selectionGenerator.selectionChanged()
    }

    /// Filter chip or segment selection
    static func filterSelected() {
        lightGenerator.impactOccurred()
    }

    /// Button press (standard action buttons)
    static func buttonPressed() {
        mediumGenerator.impactOccurred()
    }

    /// Set completed during workout
    static func setCompleted() {
        rigidGenerator.impactOccurred(intensity: 0.8)
    }

    /// Exercise completed (all sets done)
    static func exerciseCompleted() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Personal Record achieved!
    static func prAchieved() {
        // Double tap pattern for celebration
        heavyGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            heavyGenerator.impactOccurred()
        }
    }

    /// Workout started
    static func workoutStarted() {
        rigidGenerator.impactOccurred()
    }

    /// Workout completed
    static func workoutCompleted() {
        // Triple success pattern
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            heavyGenerator.impactOccurred()
        }
    }

    /// Weight/rep value changed (increment/decrement)
    static func valueChanged() {
        lightGenerator.impactOccurred(intensity: 0.5)
    }

    /// Drag gesture active
    static func dragActive() {
        softGenerator.impactOccurred(intensity: 0.4)
    }

    /// Threshold reached during drag
    static func thresholdReached() {
        mediumGenerator.impactOccurred()
    }

    // MARK: - Preparation

    /// Prepare generators for immediate response (call before expected interaction)
    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Prepare for workout session (all generators)
    static func prepareForWorkout() {
        prepare()
        softGenerator.prepare()
    }
}
