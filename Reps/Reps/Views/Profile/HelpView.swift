import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section {
                DisclosureGroup {
                    Text("Reps helps you track your workouts with structured programs. Start by activating a program from the Programs tab, or tap Quick Start on the Home screen for a freestyle session.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                } label: {
                    Label("Getting Started", systemImage: "flag.fill")
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                DisclosureGroup {
                    Text("Programs are organized into Phases, Weeks, and Days. Each day contains a workout template with exercises and sets. Activate a program and set your training schedule to see daily workouts on your Home screen. You can pause, skip, or restart at any point.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                } label: {
                    Label("Programs", systemImage: "list.bullet.clipboard.fill")
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                DisclosureGroup {
                    Text("During a workout, tap each set to mark it complete. Use the +/- buttons to adjust weight and reps. For timed exercises, use the countdown timer. Swipe between exercises or tap the exercise name to navigate. When you're done, tap Finish to save your session.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                } label: {
                    Label("Workout Tracking", systemImage: "figure.strengthtraining.traditional")
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                DisclosureGroup {
                    Text("Browse all available exercises in the Exercises tab. Each exercise shows target muscles, equipment needed, and a demo video when available. Tap any exercise to see detailed instructions and your history with that movement.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                } label: {
                    Label("Exercise Library", systemImage: "books.vertical.fill")
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                DisclosureGroup {
                    Text("Personal records are tracked automatically. When you lift heavier, do more reps, or beat a previous time, a new PR is recorded. View all your records from the Profile tab. Your workout history shows every completed session with detailed stats.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                } label: {
                    Label("Progress Tracking", systemImage: "trophy.fill")
                        .foregroundStyle(RepsTheme.Colors.text)
                }
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Help & Tips")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
    .preferredColorScheme(.dark)
}
