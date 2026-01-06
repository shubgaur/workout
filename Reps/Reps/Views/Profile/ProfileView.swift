import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endTime != nil }) private var completedWorkouts: [WorkoutSession]
    @Query private var personalRecords: [PersonalRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RepsTheme.Spacing.lg) {
                    // Stats Overview
                    StatsOverviewSection(
                        workoutCount: completedWorkouts.count,
                        prCount: personalRecords.count,
                        totalVolume: totalVolume
                    )

                    // Activity Graph
                    ContributionGraphView(workouts: completedWorkouts)

                    // Recent PRs
                    RecentPRsSection()

                    // Quick Links
                    VStack(spacing: RepsTheme.Spacing.sm) {
                        NavigationLink {
                            PersonalRecordsView()
                        } label: {
                            ProfileMenuRow(
                                icon: "trophy.fill",
                                title: "Personal Records",
                                iconColor: RepsTheme.Colors.warning
                            )
                        }

                        NavigationLink {
                            SettingsView()
                        } label: {
                            ProfileMenuRow(
                                icon: "gearshape.fill",
                                title: "Settings",
                                iconColor: RepsTheme.Colors.textSecondary
                            )
                        }
                    }
                }
                .padding(RepsTheme.Spacing.md)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Profile")
        }
    }

    private var totalVolume: Double {
        completedWorkouts.reduce(0) { $0 + $1.totalVolume }
    }
}

// MARK: - Stats Overview Section

struct StatsOverviewSection: View {
    let workoutCount: Int
    let prCount: Int
    let totalVolume: Double

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            Text("STATS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(spacing: RepsTheme.Spacing.md) {
                ProfileStatCard(
                    value: "\(workoutCount)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional"
                )

                ProfileStatCard(
                    value: "\(prCount)",
                    label: "PRs",
                    icon: "trophy.fill"
                )

                ProfileStatCard(
                    value: formatVolume(totalVolume),
                    label: "Volume",
                    icon: "scalemass.fill"
                )
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.0fK", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Profile Stat Card

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(RepsTheme.Colors.accent)

            Text(value)
                .font(RepsTheme.Typography.monoLarge)
                .foregroundStyle(RepsTheme.Colors.text)

            Text(label)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}

// MARK: - Profile Menu Row

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}
