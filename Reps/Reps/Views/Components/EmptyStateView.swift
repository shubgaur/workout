import SwiftUI

// MARK: - Empty State View

/// Standardized empty state component with optional action
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            // Icon with glow effect
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(RepsTheme.Colors.accent.opacity(0.6))
                .shadow(color: RepsTheme.Colors.accent.opacity(0.3), radius: 20)

            VStack(spacing: RepsTheme.Spacing.xs) {
                Text(title)
                    .font(RepsTheme.Typography.title3)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text(message)
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.buttonPressed()
                    action()
                }) {
                    Text(actionTitle)
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, RepsTheme.Spacing.xl)
                        .padding(.vertical, RepsTheme.Spacing.sm)
                        .background(RepsTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScalingPressButtonStyle())
            }
        }
        .padding(RepsTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// No workouts yet
    static func noWorkouts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "dumbbell",
            title: "No Workouts Yet",
            message: "Start your first workout to begin tracking your progress",
            actionTitle: "Start Workout",
            action: action
        )
    }

    /// No exercises found
    static func noExercises(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "figure.strengthtraining.traditional",
            title: "No Exercises Found",
            message: "Try adjusting your filters or search term",
            actionTitle: "Clear Filters",
            action: action
        )
    }

    /// No personal records
    static var noRecords: EmptyStateView {
        EmptyStateView(
            icon: "trophy",
            title: "No Personal Records",
            message: "Complete workouts to start setting personal records"
        )
    }

    /// No history
    static var noHistory: EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "No History",
            message: "Your completed workouts will appear here"
        )
    }

    /// No programs
    static func noPrograms(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.clipboard",
            title: "No Programs",
            message: "Create a program to organize your workout routine",
            actionTitle: "Create Program",
            action: action
        )
    }

    /// Search no results
    static func searchNoResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No matches found for \"\(query)\""
        )
    }

    /// Offline state
    static var offline: EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Connect to the internet to sync your data"
        )
    }

    /// Error state
    static func error(message: String, retry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: message,
            actionTitle: "Try Again",
            action: retry
        )
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: RepsTheme.Spacing.xxl) {
            EmptyStateView.noWorkouts {}
                .frame(height: 300)

            Divider()

            EmptyStateView.noRecords
                .frame(height: 250)

            Divider()

            EmptyStateView.searchNoResults(query: "bench press")
                .frame(height: 250)
        }
    }
    .background(RepsTheme.Colors.background)
}
